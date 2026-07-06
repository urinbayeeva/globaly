import 'dart:convert';
import 'dart:io';

import '../../../../core/services/backend_api.dart';
import '../../domain/entities/translation_result.dart';

class DocumentTranslator {
  DocumentTranslator(this._api);
  final BackendApi _api;

  bool get isConfigured => _api.isConfigured;

  Future<TranslationResult> translate(File image) async {
    final List<int> bytes = await image.readAsBytes();
    final Map<String, dynamic> json = await _api.post(
      '/v1/translate/document',
      <String, dynamic>{
        'image_base64': base64Encode(bytes),
        'image_mime_type': _mimeFor(image.path),
      },
    );
    return _toEntity(json);
  }

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
