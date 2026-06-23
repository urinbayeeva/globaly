import 'dart:io';

import '../../../../core/services/gemini_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/translation_result.dart';

class DocumentTranslator {
  DocumentTranslator(this._client);
  final GeminiClient _client;

  bool get isConfigured => _client.isConfigured;

  Future<TranslationResult> translate(File image) async {
    final List<int> bytes = await image.readAsBytes();
    final String mime = _mimeFor(image.path);

    final Map<String, dynamic> json = await _client.generateJson(
      prompt: _prompt,
      schema: _schema,
      imageBytes: bytes,
      imageMimeType: mime,
      temperature: 0.1,
    );
    return _toEntity(json);
  }

  static const String _prompt = '''
You help a migrant understand a document they photographed in a foreign
country. Do all of the following:

1) Detect the source language of the document and return its English name in
   "detectedLanguage" (e.g. "German", "Turkish", "Korean").
2) Identify what the document is in 2–4 words in "documentType"
   (e.g. "Rental agreement", "Bank letter", "Registration form", "Bill").
3) In "translation", translate ALL readable text faithfully and completely
   into the response language. Preserve the structure — labels, fields,
   amounts, dates — using line breaks. Keep numbers, dates, currency codes
   and proper names as-is.
4) In "summary", write 1–2 plain sentences explaining what this document is
   and why it matters to the user.
5) In "nextSteps", list up to 3 short, concrete actions the user should take
   (e.g. "Sign and return before the date shown", "Bring this to the town
   hall"). Use an empty list if none apply.

If the image contains no readable text, set "documentType" to "unknown",
leave "translation" empty, and explain that politely in "summary".
''';

  static const Map<String, dynamic> _schema = <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'detectedLanguage': <String, dynamic>{'type': 'string'},
      'documentType': <String, dynamic>{'type': 'string'},
      'translation': <String, dynamic>{'type': 'string'},
      'summary': <String, dynamic>{'type': 'string'},
      'nextSteps': <String, dynamic>{
        'type': 'array',
        'items': <String, dynamic>{'type': 'string'},
      },
    },
    'required': <String>[
      'detectedLanguage',
      'documentType',
      'translation',
      'summary',
      'nextSteps',
    ],
  };

  TranslationResult _toEntity(Map<String, dynamic> j) {
    final List<String> steps =
        ((j['nextSteps'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic e) => e?.toString().trim() ?? '')
            .where((String s) => s.isNotEmpty)
            .toList();
    return TranslationResult(
      detectedLanguage: _str(j['detectedLanguage']),
      documentType: _str(j['documentType']),
      translation: _str(j['translation']),
      summary: _str(j['summary']),
      nextSteps: steps,
    );
  }

  String _mimeFor(String path) {
    final String p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.heic') || p.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  static String _str(Object? v) => v is String ? v.trim() : '';
}

TranslationResult translatorOfflineFallback() {
  appLogger.w('🌐 Document translator: no AI key — returning offline notice');
  return const TranslationResult(
    detectedLanguage: '',
    documentType: 'unknown',
    translation: '',
    summary: 'AI is not configured on this build. Add a GEMINI_API_KEY or '
        'GROQ_API_KEY to .env.json to enable document translation.',
  );
}
