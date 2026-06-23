import 'package:equatable/equatable.dart';

import 'chat_message.dart';

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  final String id;

  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  Conversation copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) =>
      Conversation(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        messages: messages ?? this.messages,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'messages': messages
            .map(
              (ChatMessage m) => <String, dynamic>{
                'id': m.id,
                'sender': m.sender.name,
                'text': m.text,
                'timestamp': m.timestamp.millisecondsSinceEpoch,
                if (m.hasImage) 'imagePath': m.imagePath,
              },
            )
            .toList(),
      };

  static Conversation? fromJson(Map<String, dynamic> j) {
    try {
      final List<dynamic> rawMessages =
          (j['messages'] as List<dynamic>?) ?? <dynamic>[];
      final List<ChatMessage> messages = rawMessages
          .whereType<Map<String, dynamic>>()
          .map<ChatMessage>((Map<String, dynamic> m) {
        final String senderCode = (m['sender'] as String?) ?? 'assistant';
        final ChatSender sender =
            senderCode == 'user' ? ChatSender.user : ChatSender.assistant;
        return ChatMessage(
          id: m['id'] as String? ?? '',
          sender: sender,
          text: m['text'] as String? ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            (m['timestamp'] as int?) ?? 0,
          ),
          imagePath: m['imagePath'] as String?,
        );
      }).toList();
      return Conversation(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? 'New chat',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (j['createdAt'] as int?) ?? 0,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (j['updatedAt'] as int?) ?? 0,
        ),
        messages: messages,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props =>
      <Object?>[id, title, createdAt, updatedAt, messages];
}
