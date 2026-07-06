import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../utils/app_logger.dart';

class Env {
  Env._();

  static String _backendUrl =
      _normalized(const String.fromEnvironment('BACKEND_URL'));

  static String get backendUrl => _backendUrl;

  static Future<void> load() async {
    if (_backendUrl.isNotEmpty) return;
    try {
      final String raw = await rootBundle.loadString('.env.json');
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      _backendUrl = _normalized((map['BACKEND_URL'] as String?) ?? '');
    } catch (e) {
      appLogger.w('🔑 Env: could not load .env.json asset: $e');
    }
  }

  static String _normalized(String url) {
    final String trimmed = url.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}
