import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/gemini_chat_datasource.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';

class ChatState extends Equatable {
  const ChatState({
    this.conversationId = '',
    this.title = '',
    this.messages = const <ChatMessage>[],
    this.typing = false,
  });

  final String conversationId;
  final String title;
  final List<ChatMessage> messages;
  final bool typing;

  bool get hasUserMessage =>
      messages.any((ChatMessage m) => m.sender == ChatSender.user);

  ChatState copyWith({
    String? conversationId,
    String? title,
    List<ChatMessage>? messages,
    bool? typing,
  }) =>
      ChatState(
        conversationId: conversationId ?? this.conversationId,
        title: title ?? this.title,
        messages: messages ?? this.messages,
        typing: typing ?? this.typing,
      );

  @override
  List<Object?> get props => <Object?>[conversationId, title, messages, typing];
}

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._ds, this._repo) : super(const ChatState()) {
    _bootstrap();
  }

  final ChatDataSource _ds;
  final ChatRepository _repo;

  void _bootstrap() {
    final String? activeId = _repo.activeId();
    if (activeId != null) {
      final Conversation? existing = _repo.byId(activeId);
      if (existing != null && existing.messages.isNotEmpty) {
        emit(
          ChatState(
            conversationId: existing.id,
            title: existing.title,
            messages: existing.messages,
          ),
        );
        return;
      }
    }
    emit(ChatState(messages: _ds.seed()));
  }

  void startNew() {
    _repo.setActiveId(null);
    emit(ChatState(messages: _ds.seed()));
  }

  void open(String id) {
    final Conversation? c = _repo.byId(id);
    if (c == null) return;
    _repo.setActiveId(id);
    emit(
      ChatState(
        conversationId: id,
        title: c.title,
        messages: c.messages,
      ),
    );
  }

  Future<void> send(String text, {String? imagePath}) async {
    final String trimmed = text.trim();
    final bool hasImage = imagePath != null && imagePath.isNotEmpty;

    if (trimmed.isEmpty && !hasImage) return;
    final ChatMessage user = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sender: ChatSender.user,
      text: trimmed,
      timestamp: DateTime.now(),
      imagePath: hasImage ? imagePath : null,
    );
    final List<ChatMessage> withUser = <ChatMessage>[...state.messages, user];

    final bool isFirstSend = state.conversationId.isEmpty;
    final String convId = isFirstSend
        ? 'conv_${DateTime.now().microsecondsSinceEpoch}'
        : state.conversationId;
    final String convTitle = state.title.isEmpty
        ? _titleFrom(trimmed.isEmpty ? '📷 Photo' : trimmed)
        : state.title;

    emit(
      state.copyWith(
        conversationId: convId,
        title: convTitle,
        messages: withUser,
        typing: true,
      ),
    );
    if (isFirstSend) await _repo.setActiveId(convId);
    await _persist(convId, convTitle, withUser);

    final ChatMessage full = await _ds.reply(
      userText: trimmed,
      history: withUser,
      imagePath: hasImage ? imagePath : null,
    );
    if (isClosed) return;
    await _streamReply(convId, convTitle, withUser, full);
  }

  Future<void> _streamReply(
    String convId,
    String convTitle,
    List<ChatMessage> beforeReply,
    ChatMessage full,
  ) async {
    final List<String> tokens = _tokenize(full.text);
    if (tokens.isEmpty) {
      final List<ChatMessage> finalList = <ChatMessage>[...beforeReply, full];
      if (isClosed) return;
      emit(state.copyWith(messages: finalList, typing: false));
      await _persist(convId, convTitle, finalList);
      return;
    }
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < tokens.length; i++) {
      if (isClosed) return;
      buffer.write(tokens[i]);
      final List<ChatMessage> partial = <ChatMessage>[
        ...beforeReply,
        ChatMessage(
          id: full.id,
          sender: full.sender,
          text: buffer.toString(),
          timestamp: full.timestamp,
        ),
      ];
      emit(
        state.copyWith(
          messages: partial,
          typing: i < tokens.length - 1,
        ),
      );
      if (i < tokens.length - 1) {
        await Future<void>.delayed(_delayFor(tokens[i + 1]));
      }
    }
    await _persist(convId, convTitle, state.messages);
  }

  Future<void> _persist(
    String id,
    String title,
    List<ChatMessage> messages,
  ) async {
    final DateTime now = DateTime.now();
    final Conversation? existing = _repo.byId(id);
    final Conversation conv = Conversation(
      id: id,
      title: title,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      messages: messages,
    );
    await _repo.upsert(conv);
  }

  String _titleFrom(String userText) {
    final String trimmed = userText.trim();
    if (trimmed.length <= 42) return trimmed;
    return '${trimmed.substring(0, 40).trim()}…';
  }

  List<String> _tokenize(String text) {
    final List<String> out = <String>[];
    final RegExp pattern = RegExp(r'\S+\s*|\s+');
    for (final RegExpMatch m in pattern.allMatches(text)) {
      out.add(m.group(0)!);
    }
    return out;
  }

  Duration _delayFor(String nextToken) {
    final String stripped = nextToken.trimRight();
    if (stripped.isEmpty) return const Duration(milliseconds: 20);
    final String last = stripped[stripped.length - 1];
    if (last == '.' || last == '!' || last == '?') {
      return const Duration(milliseconds: 110);
    }
    if (last == ',' || last == ';' || last == ':') {
      return const Duration(milliseconds: 70);
    }
    return const Duration(milliseconds: 35);
  }
}
