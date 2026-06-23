import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/env.dart';
import '../di/injector.dart';
import '../storage/prefs.dart';
import '../utils/app_logger.dart';
import 'groq_client.dart';

class MissingGeminiKey implements Exception {
  const MissingGeminiKey();
  @override
  String toString() => 'GEMINI_API_KEY not provided at build time';
}

class GeminiRateLimited implements Exception {
  const GeminiRateLimited(this.retryAfter);
  final Duration retryAfter;
  @override
  String toString() =>
      'Gemini rate-limited, retry after ${retryAfter.inSeconds}s';
}

class GeminiUnavailable implements Exception {
  const GeminiUnavailable(this.statusCode);
  final int statusCode;
  @override
  String toString() => 'Gemini upstream HTTP $statusCode';
}

class GeminiClient {
  GeminiClient(this._dio, {GroqClient? fallback}) : _fallback = fallback;
  final Dio _dio;
  final GroqClient? _fallback;

  String get _apiKey => Env.geminiApiKey;

  static const List<String> _models = <String>[
    'gemini-flash-latest',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
  ];

  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models';

  bool get isConfigured =>
      _apiKey.isNotEmpty || (_fallback != null && _fallback.isConfigured);

  bool get hasOwnKey => _apiKey.isNotEmpty;

  String _localeDirective() {
    try {
      final String code = sl<Prefs>().getString(Prefs.kAppLocale) ?? 'en';
      switch (code) {
        case 'ru':
          return 'Respond entirely in Russian (русский). All text fields, '
              'titles, descriptions, summaries, notes, and explanations '
              'must be in Russian. JSON keys stay in English. '
              'Numbers, dates and currency codes stay numeric.';
        case 'uz':
          return "Respond entirely in Uzbek (O'zbek, Latin script). All "
              'text fields, titles, descriptions, summaries, notes, and '
              'explanations must be in Uzbek. JSON keys stay in English. '
              'Numbers, dates and currency codes stay numeric.';
        case 'en':
        default:
          return 'Respond entirely in English.';
      }
    } catch (_) {
      return 'Respond entirely in English.';
    }
  }

  String _localised(String prompt) => '${_localeDirective()}\n\n$prompt';

  Future<Map<String, dynamic>> generateJson({
    required String prompt,
    required Map<String, dynamic> schema,
    double temperature = 0.2,
    List<int>? imageBytes,
    String imageMimeType = 'image/jpeg',
  }) async {
    final String localisedPrompt = _localised(prompt);

    if (_apiKey.isEmpty) {
      if (_fallback != null && _fallback.isConfigured) {
        try {
          return await _fallback.generateJson(
            prompt: localisedPrompt,
            schema: schema,
            temperature: temperature,
            imageBytes: imageBytes,
            imageMimeType: imageMimeType,
          );
        } on GroqRateLimited {
          throw const GeminiRateLimited(Duration(seconds: 30));
        }
      }
      throw const MissingGeminiKey();
    }

    Duration? lastRetryAfter;
    Object? lastError;
    for (final String model in _models) {
      try {
        return await _call(
          model,
          localisedPrompt,
          schema,
          temperature,
          imageBytes,
          imageMimeType,
        );
      } on GeminiRateLimited catch (e) {
        lastRetryAfter = e.retryAfter;
        appLogger.w('🤖 $model rate-limited, trying next');
        continue;
      } on GeminiUnavailable catch (e) {
        lastError = e;
        appLogger.w('🤖 $model upstream ${e.statusCode}, trying next');
        continue;
      } on DioException catch (e) {
        final int? code = e.response?.statusCode;
        if (code != null && code >= 500) {
          lastError = e;
          appLogger.w('🤖 $model upstream HTTP $code, trying next');
          continue;
        }
        rethrow;
      } on FormatException catch (e) {
        if (e.message.contains('404') || e.message.contains('400')) {
          lastError = e;
          appLogger.w('🤖 $model unavailable (${e.message}), trying next');
          continue;
        }
        rethrow;
      }
    }

    if (_fallback != null && _fallback.isConfigured) {
      try {
        appLogger.w('🤖 Gemini exhausted, falling back to Groq');
        return await _fallback.generateJson(
          prompt: localisedPrompt,
          schema: schema,
          temperature: temperature,
          imageBytes: imageBytes,
          imageMimeType: imageMimeType,
        );
      } catch (e) {
        appLogger.w('🐇 Groq fallback also failed: $e');
      }
    }

    if (lastRetryAfter != null) throw GeminiRateLimited(lastRetryAfter);
    throw FormatException(
      'All Gemini models failed${lastError == null ? '' : ': $lastError'}',
    );
  }

  Future<String> generateText({
    required String prompt,
    String systemPrompt = '',
    List<Map<String, String>> history = const <Map<String, String>>[],
    double temperature = 0.6,
    int maxOutputTokens = 1024,
    List<int>? imageBytes,
    String imageMimeType = 'image/jpeg',
  }) async {
    if (_apiKey.isEmpty) {
      if (_fallback != null && _fallback.isConfigured) {
        try {
          return await _fallback.generateText(
            prompt: prompt,
            systemPrompt: systemPrompt,
            history: history,
            temperature: temperature,
            imageBytes: imageBytes,
            imageMimeType: imageMimeType,
          );
        } on GroqRateLimited {
          throw const GeminiRateLimited(Duration(seconds: 30));
        }
      }
      throw const MissingGeminiKey();
    }

    Duration? lastRetryAfter;
    Object? lastError;
    for (final String model in _models) {
      try {
        return await _callText(
          model: model,
          prompt: prompt,
          systemPrompt: systemPrompt,
          history: history,
          temperature: temperature,
          maxOutputTokens: maxOutputTokens,
          imageBytes: imageBytes,
          imageMimeType: imageMimeType,
        );
      } on GeminiRateLimited catch (e) {
        lastRetryAfter = e.retryAfter;
        appLogger.w('🤖 $model rate-limited, trying next');
        continue;
      } on GeminiUnavailable catch (e) {
        lastError = e;
        appLogger.w('🤖 $model upstream ${e.statusCode}, trying next');
        continue;
      } on DioException catch (e) {
        final int? code = e.response?.statusCode;
        if (code != null && code >= 500) {
          lastError = e;
          appLogger.w('🤖 $model upstream HTTP $code, trying next');
          continue;
        }
        rethrow;
      } on FormatException catch (e) {
        if (e.message.contains('404') || e.message.contains('400')) {
          lastError = e;
          appLogger.w('🤖 $model unavailable (${e.message}), trying next');
          continue;
        }
        rethrow;
      }
    }

    if (_fallback != null && _fallback.isConfigured) {
      try {
        appLogger.w('🤖 Gemini exhausted, falling back to Groq for chat');
        return await _fallback.generateText(
          prompt: prompt,
          systemPrompt: systemPrompt,
          history: history,
          temperature: temperature,
          imageBytes: imageBytes,
          imageMimeType: imageMimeType,
        );
      } catch (e) {
        appLogger.w('🐇 Groq fallback also failed: $e');
      }
    }

    if (lastRetryAfter != null) throw GeminiRateLimited(lastRetryAfter);
    throw FormatException(
      'All Gemini models failed${lastError == null ? '' : ': $lastError'}',
    );
  }

  Future<String> _callText({
    required String model,
    required String prompt,
    required String systemPrompt,
    required List<Map<String, String>> history,
    required double temperature,
    int maxOutputTokens = 1024,
    List<int>? imageBytes,
    String imageMimeType = 'image/jpeg',
  }) async {
    final List<Map<String, dynamic>> contents = <Map<String, dynamic>>[
      for (final Map<String, String> turn in history)
        <String, dynamic>{
          'role': turn['role'] ?? 'user',
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{'text': turn['text'] ?? ''},
          ],
        },
      <String, dynamic>{
        'role': 'user',
        'parts': <Map<String, dynamic>>[
          <String, dynamic>{'text': prompt},
          if (imageBytes != null)
            <String, dynamic>{
              'inline_data': <String, dynamic>{
                'mime_type': imageMimeType,
                'data': base64Encode(imageBytes),
              },
            },
        ],
      },
    ];

    final bool supportsThinking =
        model.contains('2.5') || model == 'gemini-flash-latest';
    final Map<String, dynamic> body = <String, dynamic>{
      'contents': contents,
      'generationConfig': <String, dynamic>{
        'temperature': temperature,
        'responseMimeType': 'text/plain',
        'maxOutputTokens': maxOutputTokens,
        if (supportsThinking)
          'thinkingConfig': <String, dynamic>{'thinkingBudget': 0},
      },
      'systemInstruction': <String, dynamic>{
        'parts': <Map<String, dynamic>>[
          <String, dynamic>{
            'text': systemPrompt.isEmpty
                ? _localeDirective()
                : '${_localeDirective()}\n\n$systemPrompt',
          },
        ],
      },
    };

    final Response<dynamic> res = await _dio.post<dynamic>(
      '$_endpoint/$model:generateContent',
      queryParameters: <String, dynamic>{'key': _apiKey},
      data: body,
      options: Options(
        headers: <String, String>{'Content-Type': 'application/json'},
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 15),
        validateStatus: (int? _) => true,
      ),
    );

    final int? code = res.statusCode;
    if (code == 429) {
      throw GeminiRateLimited(_extractRetryAfter(res));
    }
    if (code != null && code >= 500) {
      throw GeminiUnavailable(code);
    }
    if (code != 200) {
      throw FormatException('Gemini HTTP $code');
    }

    final Map<String, dynamic> json = res.data is String
        ? jsonDecode(res.data as String) as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    final String text = _extractText(json).trim();
    if (text.isEmpty) {
      throw const FormatException('Gemini returned no content');
    }
    return text;
  }

  Future<Map<String, dynamic>> _call(
    String model,
    String prompt,
    Map<String, dynamic> schema,
    double temperature, [
    List<int>? imageBytes,
    String imageMimeType = 'image/jpeg',
  ]) async {
    final List<Map<String, dynamic>> parts = <Map<String, dynamic>>[
      <String, dynamic>{'text': prompt},
      if (imageBytes != null)
        <String, dynamic>{
          'inline_data': <String, dynamic>{
            'mime_type': imageMimeType,
            'data': base64Encode(imageBytes),
          },
        },
    ];
    final Map<String, dynamic> body = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'user',
          'parts': parts,
        },
      ],
      'generationConfig': <String, dynamic>{
        'temperature': temperature,
        'responseMimeType': 'application/json',
        'responseSchema': schema,
      },
    };

    final Response<dynamic> res = await _dio.post<dynamic>(
      '$_endpoint/$model:generateContent',
      queryParameters: <String, dynamic>{'key': _apiKey},
      data: body,
      options: Options(
        headers: <String, String>{'Content-Type': 'application/json'},
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 15),
        validateStatus: (int? _) => true,
      ),
    );

    final int? code = res.statusCode;
    if (code == 429) {
      throw GeminiRateLimited(_extractRetryAfter(res));
    }
    if (code != null && code >= 500) {
      throw GeminiUnavailable(code);
    }
    if (code != 200) {
      throw FormatException('Gemini HTTP $code');
    }

    final Map<String, dynamic> json = res.data is String
        ? jsonDecode(res.data as String) as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    final String text = _extractText(json);
    if (text.isEmpty) {
      throw const FormatException('Gemini returned no content');
    }
    return jsonDecode(text) as Map<String, dynamic>;
  }

  Duration _extractRetryAfter(Response<dynamic> res) {
    try {
      final dynamic data = res.data;
      final Map<String, dynamic> body = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : data as Map<String, dynamic>;
      final List<dynamic>? details = (body['error']
          as Map<String, dynamic>?)?['details'] as List<dynamic>?;
      if (details == null) return const Duration(seconds: 60);
      for (final dynamic d in details) {
        if (d is Map<String, dynamic> &&
            (d['@type'] as String?)?.contains('RetryInfo') == true) {
          final String s = (d['retryDelay'] as String?) ?? '';
          final RegExpMatch? m = RegExp(r'^([0-9.]+)s$').firstMatch(s);
          if (m != null) {
            final double secs = double.tryParse(m.group(1)!) ?? 60;
            return Duration(milliseconds: (secs * 1000).round());
          }
        }
      }
    } catch (_) {}
    return const Duration(seconds: 60);
  }

  String _extractText(Map<String, dynamic> body) {
    final List<dynamic>? candidates = body['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return '';
    final Map<String, dynamic>? content = (candidates.first
        as Map<String, dynamic>)['content'] as Map<String, dynamic>?;
    final List<dynamic>? parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return '';
    return ((parts.first as Map<String, dynamic>)['text'] as String?) ?? '';
  }
}
