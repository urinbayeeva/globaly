import 'dart:convert';
import 'dart:io';

import '../../../../core/services/backend_api.dart';
import '../../domain/entities/scan_analysis.dart';

class GeminiContractAnalyzer {
  GeminiContractAnalyzer(this._api);
  final BackendApi _api;

  bool get isConfigured => _api.isConfigured;

  Future<ScanAnalysis> analyze(File image) async {
    final List<int> bytes = await image.readAsBytes();
    final Map<String, dynamic> json = await _api.post(
      '/v1/scan/analyze',
      <String, dynamic>{
        'image_base64': base64Encode(bytes),
        'image_mime_type': _mimeFor(image.path),
      },
    );
    return _toEntity(json);
  }

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
