import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../utils/app_logger.dart';

class Env {
  Env._();

  static String _gemini = const String.fromEnvironment('GEMINI_API_KEY');
  static String _groq = const String.fromEnvironment('GROQ_API_KEY');
  static String _resend = const String.fromEnvironment('RESEND_API_KEY');

  static String _resendFrom = const String.fromEnvironment(
    'RESEND_FROM',
    defaultValue: 'Globaly <onboarding@resend.dev>',
  );

  static String get geminiApiKey => _gemini;
  static String get groqApiKey => _groq;
  static String get resendApiKey => _resend;
  static String get resendFrom => _resendFrom;

  static Future<void> load() async {
    if (_gemini.isNotEmpty && _groq.isNotEmpty && _resend.isNotEmpty) return;
    try {
      final String raw = await rootBundle.loadString('.env.json');
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      if (_gemini.isEmpty) {
        _gemini = (map['GEMINI_API_KEY'] as String?)?.trim() ?? '';
      }
      if (_groq.isEmpty) {
        _groq = (map['GROQ_API_KEY'] as String?)?.trim() ?? '';
      }
      if (_resend.isEmpty) {
        _resend = (map['RESEND_API_KEY'] as String?)?.trim() ?? '';
      }
      final String? from = (map['RESEND_FROM'] as String?)?.trim();
      if (from != null && from.isNotEmpty) _resendFrom = from;
    } catch (e) {
      appLogger.w('🔑 Env: could not load .env.json asset: $e');
    }
  }
}
