import 'dart:io';

import '../../../../core/services/gemini_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/scan_analysis.dart';

class GeminiContractAnalyzer {
  GeminiContractAnalyzer(this._client);
  final GeminiClient _client;

  bool get isConfigured => _client.isConfigured;

  Future<ScanAnalysis> analyze(File image) async {
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
You are a careful legal document reviewer for migrants. The user has
photographed a document. Do two things:

1) Identify the document type. Return one of:
   "contract" | "passport" | "diploma" | "id_card" | "transcript" |
   "certificate" | "unknown".

2) If — and only if — it is a contract (employment, rental, service,
   freelance, etc.), evaluate it from the user's perspective:
   - List up to 5 RISKY clauses with severity "dangerous" | "warning" |
     "notice". For each risk include: title (≤7 words), severity, a SHORT
     verbatim quote from the document (≤25 words), and a 1–2 sentence
     explanation in plain English of why the user should care.
   - List up to 3 FAIR / SAFE points (clauses that protect the user, e.g.
     reasonable notice period, clear scope, mutual termination).
   - Write a 1-sentence summary.

If the document is NOT a contract, leave "risks" and "safePoints" empty
and set "summary" to a polite single-sentence reply like
"This looks like a [TYPE]. Please scan a contract for risk analysis."

Also always return the raw text you extracted from the image in
"rawText" (best-effort transcription).
''';

  static const Map<String, dynamic> _schema = <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'documentType': <String, dynamic>{'type': 'string'},
      'summary': <String, dynamic>{'type': 'string'},
      'rawText': <String, dynamic>{'type': 'string'},
      'risks': <String, dynamic>{
        'type': 'array',
        'items': <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{
            'title': <String, dynamic>{'type': 'string'},
            'severity': <String, dynamic>{'type': 'string'},
            'quote': <String, dynamic>{'type': 'string'},
            'explanation': <String, dynamic>{'type': 'string'},
          },
          'required': <String>['title', 'severity', 'quote', 'explanation'],
        },
      },
      'safePoints': <String, dynamic>{
        'type': 'array',
        'items': <String, dynamic>{'type': 'string'},
      },
    },
    'required': <String>[
      'documentType',
      'summary',
      'rawText',
      'risks',
      'safePoints',
    ],
  };

  ScanAnalysis _toEntity(Map<String, dynamic> j) {
    final DocumentType type = _docTypeFor(_str(j['documentType']));
    final List<dynamic> rawRisks =
        (j['risks'] as List<dynamic>?) ?? <dynamic>[];
    final List<DetectedRisk> risks = rawRisks
        .whereType<Map<String, dynamic>>()
        .map(_toRisk)
        .where((DetectedRisk r) => r.title.isNotEmpty)
        .toList();
    final List<String> safePoints =
        ((j['safePoints'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic e) => e?.toString().trim() ?? '')
            .where((String s) => s.isNotEmpty)
            .toList();
    return ScanAnalysis(
      rawText: _str(j['rawText']),
      type: type,
      summary: _str(j['summary']),
      risks: risks,
      safePoints: safePoints,
    );
  }

  DocumentType _docTypeFor(String code) {
    for (final DocumentType t in DocumentType.values) {
      if (t.code == code.trim().toLowerCase()) return t;
    }
    return DocumentType.unknown;
  }

  DetectedRisk _toRisk(Map<String, dynamic> j) => DetectedRisk(
        title: _str(j['title']),
        severity: _severityFor(_str(j['severity'])),
        quote: _str(j['quote']),
        explanation: _str(j['explanation']),
      );

  RiskSeverity _severityFor(String code) {
    switch (code.trim().toLowerCase()) {
      case 'dangerous':
        return RiskSeverity.dangerous;
      case 'warning':
        return RiskSeverity.warning;
      case 'notice':
      default:
        return RiskSeverity.notice;
    }
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

ScanAnalysis offlineFallback() {
  appLogger.w('🔍 Contract analyzer: no AI key — returning offline notice');
  return const ScanAnalysis(
    rawText: '',
    type: DocumentType.unknown,
    summary: 'AI is not configured on this build. Add a GEMINI_API_KEY or '
        'GROQ_API_KEY to .env.json (Groq powers vision via Llama-4 Scout) '
        'to enable document analysis.',
    risks: <DetectedRisk>[],
  );
}
