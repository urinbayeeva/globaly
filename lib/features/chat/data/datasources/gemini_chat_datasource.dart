import 'dart:io';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/services/gemini_client.dart';
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
  GeminiChatDataSource(this._client, this._prefs, this._countries);

  final GeminiClient _client;
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
    final String text = _client.isConfigured
        ? await _callGemini(userText, history, imagePath)
        : _fallback(userText);
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sender: ChatSender.assistant,
      text: text,
      timestamp: DateTime.now(),
    );
  }

  Future<String> _callGemini(
    String userText,
    List<ChatMessage> history,
    String? imagePath,
  ) async {
    try {
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

      List<int>? imageBytes;
      String mime = 'image/jpeg';
      if (imagePath != null && imagePath.isNotEmpty) {
        final File file = File(imagePath);
        if (await file.exists()) {
          imageBytes = await file.readAsBytes();
          mime = _mimeFor(imagePath);
        }
      }

      final String prompt = userText.trim().isEmpty && imageBytes != null
          ? 'Describe this image and explain anything relevant to someone '
              'moving abroad (e.g. what a form/sign/document means and what '
              'to do next).'
          : userText;

      final String raw = await _client.generateText(
        systemPrompt: _systemPrompt(),
        history: turns,
        prompt: prompt,
        imageBytes: imageBytes,
        imageMimeType: mime,
      );
      return _stripMarkdown(raw);
    } catch (e) {
      appLogger.w('💬 Gemini chat failed: $e');
      return _fallback(userText);
    }
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

  String _systemPrompt() {
    final String? destCode = _prefs.getString(Prefs.kDestinationCountry);
    final Country? country =
        destCode == null ? null : _countries.byCode(destCode);
    final Purpose purpose = Purpose.fromCode(
      _prefs.getString(Prefs.kPurpose) ?? Purpose.study.code,
    );

    final String destLine = country == null
        ? 'The user has not picked a destination country yet.'
        : 'The user is planning to move to ${country.name}.';
    return '''
You are the Globaly assistant — a friendly, practical helper for people
moving abroad. Keep answers concise (2–4 short paragraphs max), specific,
and grounded in commonly available public knowledge. If a question needs
country-specific facts you are unsure about, say so and point the user at
the official source (embassy, ministry, university).

User context:
- $destLine
- Stated purpose: ${purpose.label}.

Style:
- Use plain language; no jargon unless you define it.
- When listing steps use short numbered points (e.g. "1.", "2.") on new
  lines — do NOT use bullet stars or hyphens.
- Output PLAIN TEXT ONLY. No markdown whatsoever: no **bold**, no *italics*,
  no _underscores_, no `backticks`, no #headings, no [links](urls) — just
  the words. The chat UI shows raw characters, so any markdown marks will
  appear as literal punctuation.
- Never invent prices, dates, or document names — round to typical ranges
  or say "verify on the official site".
- Politely decline anything outside the moving-abroad / immigration scope.
''';
  }

  String _fallback(String userText) {
    final String t = userText.toLowerCase();
    if (t.contains('visa')) {
      return 'For most visas you need a passport, financial proof, an invitation '
          'or acceptance letter, and a paid fee. Check the Required Documents '
          'card on Home for your destination-specific list.';
    }
    if (t.contains('ielts') || t.contains('language')) {
      return 'Most universities accept IELTS 6.5+ for bachelor and 7.0+ for master. '
          'Set your score on the Success Score page to see which schools match.';
    }
    if (t.contains('contract') || t.contains('sign')) {
      return 'Never sign a contract abroad before scanning. The Scan tab will '
          'flag any clauses that look risky.';
    }
    return 'AI is unavailable right now. Try the Required Documents card or the '
        'Roadmap tab for step-by-step guidance, and ask me again in a moment.';
  }
}
