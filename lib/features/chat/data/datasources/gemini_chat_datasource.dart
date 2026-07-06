import 'dart:convert';
import 'dart:io';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/services/backend_api.dart';
import '../../../../core/storage/prefs.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../profile_setup/data/datasources/countries_db.dart';
import '../../../profile_setup/domain/entities/country.dart';
import '../../../profile_setup/domain/entities/purpose.dart';
import '../../domain/entities/chat_message.dart';

abstract class ChatDataSource {
  List<ChatMessage> seed();
  Future<ChatMessage> reply({
    required String userText,
    required List<ChatMessage> history,
    String? imagePath,
  });
}

class GeminiChatDataSource implements ChatDataSource {
  GeminiChatDataSource(this._api, this._prefs, this._countries);

  final BackendApi _api;
  final Prefs _prefs;
  final CountriesDb _countries;

  @override
  List<ChatMessage> seed() => <ChatMessage>[
        ChatMessage(
          id: 'welcome',
          sender: ChatSender.assistant,
          text: T.t('chat.welcome'),
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ];

  @override
  Future<ChatMessage> reply({
    required String userText,
    required List<ChatMessage> history,
    String? imagePath,
  }) async {
    String text;
    try {
      text = await _callBackend(userText, history, imagePath);
    } catch (e) {
      appLogger.w('💬 Chat backend failed: $e');
      text = T.t('chat.unavailable');
    }
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sender: ChatSender.assistant,
      text: text,
      timestamp: DateTime.now(),
    );
  }

  Future<String> _callBackend(
    String userText,
    List<ChatMessage> history,
    String? imagePath,
  ) async {
    final List<Map<String, String>> allTurns = history
        .where((ChatMessage m) => m.id != 'welcome')
        .map<Map<String, String>>(
          (ChatMessage m) => <String, String>{
            'role': m.sender == ChatSender.user ? 'user' : 'model',
            'text': m.text,
          },
        )
        .toList();

    const int maxTurns = 12;
    final List<Map<String, String>> turns = allTurns.length > maxTurns
        ? allTurns.sublist(allTurns.length - maxTurns)
        : allTurns;

    String? imageBase64;
    String mime = 'image/jpeg';
    if (imagePath != null && imagePath.isNotEmpty) {
      final File file = File(imagePath);
      if (await file.exists()) {
        imageBase64 = base64Encode(await file.readAsBytes());
        mime = _mimeFor(imagePath);
      }
    }

    final String? destCode = _prefs.getString(Prefs.kDestinationCountry);
    final Country? country =
        destCode == null ? null : _countries.byCode(destCode);
    final Purpose purpose = Purpose.fromCode(
      _prefs.getString(Prefs.kPurpose) ?? Purpose.study.code,
    );

    final Map<String, dynamic> data =
        await _api.post('/v1/chat', <String, dynamic>{
      'message': userText,
      'history': turns,
      if (imageBase64 != null) 'image_base64': imageBase64,
      'image_mime_type': mime,
      'destination_country': country?.name ?? '',
      'purpose': purpose.code,
    });
    final String text = (data['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) {
      throw const FormatException('Backend returned no text');
    }
    return _stripMarkdown(text);
  }

  String _mimeFor(String path) {
    final String p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.heic') || p.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  static final RegExp _bold = RegExp(r'\*\*(.+?)\*\*', dotAll: true);
  static final RegExp _italicAsterisk =
      RegExp(r'(?<!\*)\*(?!\*)([^*\n]+?)\*(?!\*)');
  static final RegExp _italicUnderscore =
      RegExp(r'(?<![A-Za-z0-9_])_([^_\n]+?)_(?![A-Za-z0-9_])');
  static final RegExp _heading = RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true);
  static final RegExp _fenced = RegExp(r'```[a-zA-Z0-9_-]*\n?');
  static final RegExp _inlineCode = RegExp(r'`([^`]+)`');
  static final RegExp _link = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
  static final RegExp _bulletDash =
      RegExp(r'^\s{0,3}[-*+]\s+', multiLine: true);
  static final RegExp _blankRuns = RegExp(r'\n{3,}');

  String _stripMarkdown(String input) {
    String s = input;
    s = s.replaceAllMapped(_bold, (Match m) => m.group(1) ?? '');
    s = s.replaceAllMapped(_italicAsterisk, (Match m) => m.group(1) ?? '');
    s = s.replaceAllMapped(_italicUnderscore, (Match m) => m.group(1) ?? '');
    s = s.replaceAll(_heading, '');
    s = s.replaceAll(_fenced, '');
    s = s.replaceAllMapped(_inlineCode, (Match m) => m.group(1) ?? '');

    s = s.replaceAllMapped(
      _link,
      (Match m) => '${m.group(1)} (${m.group(2)})',
    );
    s = s.replaceAll(_bulletDash, '• ');
    s = s.replaceAll(_blankRuns, '\n\n');
    return s.trim();
  }
}
