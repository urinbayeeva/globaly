import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/env.dart';
import '../di/injector.dart';
import '../storage/prefs.dart';
import '../utils/app_logger.dart';

class MissingGroqKey implements Exception {
  const MissingGroqKey();
  @override
  String toString() => 'GROQ_API_KEY not provided at build time';
}

class GroqRateLimited implements Exception {
  const GroqRateLimited();
  @override
  String toString() => 'Groq rate-limited';
}

class GroqClient {
  GroqClient(this._dio);
  final Dio _dio;

  String get _apiKey => Env.groqApiKey;

  static const List<String> _models = <String>[
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
  ];

  static const String _visionModel =
      'meta-llama/llama-4-scout-17b-16e-instruct';

  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  bool get isConfigured => _apiKey.isNotEmpty;

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

  Future<Map<String, dynamic>> generateJson({
    required String prompt,
    required Map<String, dynamic> schema,
    double temperature = 0.2,
    List<int>? imageBytes,
    String imageMimeType = 'image/jpeg',
  }) async {
    if (_apiKey.isEmpty) throw const MissingGroqKey();
    final String systemPrompt = <String>[
      _localeDirective(),
      'You return strictly valid JSON that conforms to the provided schema.',
      'Schema:',
      jsonEncode(schema),
      'Return only the JSON object — no markdown fences, no commentary.',
    ].join('\n');

    final List<String> models =
        imageBytes == null ? _models : <String>[_visionModel];

    Object? lastError;
    for (final String model in models) {
      try {
        return await _call(
          model: model,
          systemPrompt: systemPrompt,
          userPrompt: prompt,
          temperature: temperature,
          jsonMode: true,
          imageBytes: imageBytes,
          imageMimeType: imageMimeType,
        );
      } on GroqRateLimited {
        appLogger.w('🐇 $model rate-limited, trying next');
        continue;
      } on FormatException catch (e) {
        if (e.message.contains('404') || e.message.contains('400')) {
          lastError = e;
          appLogger.w('🐇 $model unavailable (${e.message}), trying next');
          continue;
        }
        rethrow;
      } on DioException catch (e) {
        final int? code = e.response?.statusCode;
        if (code != null && code >= 500) {
          lastError = e;
          appLogger.w('🐇 $model upstream HTTP $code, trying next');
          continue;
        }
        rethrow;
      }
    }
    throw FormatException(
      'All Groq models failed${lastError == null ? '' : ': $lastError'}',
    );
  }

  Future<String> generateText({
    required String prompt,
    String systemPrompt = '',
    List<Map<String, String>> history = const <Map<String, String>>[],
    double temperature = 0.6,
    List<int>? imageBytes,
    String imageMimeType = 'image/jpeg',
  }) async {
    if (_apiKey.isEmpty) throw const MissingGroqKey();
    final String composedSystem = systemPrompt.isEmpty
        ? _localeDirective()
        : '${_localeDirective()}\n\n$systemPrompt';

    final List<String> models =
        imageBytes == null ? _models : <String>[_visionModel];

    Object? lastError;
    for (final String model in models) {
      try {
        return await _callText(
          model: model,
          systemPrompt: composedSystem,
          history: history,
          userPrompt: prompt,
          temperature: temperature,
          imageBytes: imageBytes,
          imageMimeType: imageMimeType,
        );
      } on GroqRateLimited {
        appLogger.w('🐇 $model rate-limited, trying next');
        continue;
      } on FormatException catch (e) {
        if (e.message.contains('404') || e.message.contains('400')) {
          lastError = e;
          appLogger.w('🐇 $model unavailable (${e.message}), trying next');
          continue;
        }
        rethrow;
      } on DioException catch (e) {
        final int? code = e.response?.statusCode;
        if (code != null && code >= 500) {
          lastError = e;
          appLogger.w('🐇 $model upstream HTTP $code, trying next');
          continue;
        }
        rethrow;
      }
    }
    throw FormatException(
      'All Groq models failed${lastError == null ? '' : ': $lastError'}',
    );
  }

  Future<Map<String, dynamic>> _call({
    required String model,
    required String systemPrompt,
    required String userPrompt,
    required double temperature,
    required bool jsonMode,
    List<int>? imageBytes,
    String imageMimeType = 'image/jpeg',
  }) async {
    final Object userContent = imageBytes == null
        ? userPrompt
        : <Map<String, dynamic>>[
            <String, dynamic>{'type': 'text', 'text': userPrompt},
            <String, dynamic>{
              'type': 'image_url',
              'image_url': <String, String>{
                'url': 'data:$imageMimeType;base64,${base64Encode(imageBytes)}',
              },
            },
          ];
    final Map<String, dynamic> body = <String, dynamic>{
      'model': model,
      'temperature': temperature,
      'messages': <Map<String, dynamic>>[
        <String, dynamic>{'role': 'system', 'content': systemPrompt},
        <String, dynamic>{'role': 'user', 'content': userContent},
      ],
      if (jsonMode) 'response_format': <String, String>{'type': 'json_object'},
    };

    final Response<dynamic> res = await _dio.post<dynamic>(
      _endpoint,
      data: body,
      options: Options(
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 15),
        validateStatus: (int? _) => true,
      ),
    );

    final int? code = res.statusCode;
    if (code == 429) throw const GroqRateLimited();
    if (code != 200) throw FormatException('Groq HTTP $code');

    final Map<String, dynamic> json = res.data is String
        ? jsonDecode(res.data as String) as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    final String content = _extractContent(json);
    if (content.isEmpty) {
      throw const FormatException('Groq returned no content');
    }
    return _decodeJsonObject(content);
  }

  Map<String, dynamic> _decodeJsonObject(String raw) {
    String s = raw.trim();

    s = s.replaceAll(RegExp(r'^```[a-zA-Z0-9_-]*\n?'), '');
    s = s.replaceAll(RegExp(r'\n?```\s*$'), '');
    try {
      final dynamic parsed = jsonDecode(s);
      if (parsed is Map<String, dynamic>) return parsed;
    } catch (_) {}

    final int start = s.indexOf('{');
    final int end = s.lastIndexOf('}');
    if (start != -1 && end > start) {
      final String sliced = s.substring(start, end + 1);
      try {
        final dynamic parsed = jsonDecode(sliced);
        if (parsed is Map<String, dynamic>) return parsed;
      } catch (_) {}
    }
    throw FormatException(
      'Groq returned non-JSON: ${s.substring(0, s.length.clamp(0, 120))}',
    );
  }

  Future<String> _callText({
    required String model,
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String userPrompt,
    required double temperature,
    List<int>? imageBytes,
    String imageMimeType = 'image/jpeg',
  }) async {
    final Object userContent = imageBytes == null
        ? userPrompt
        : <Map<String, dynamic>>[
            <String, dynamic>{'type': 'text', 'text': userPrompt},
            <String, dynamic>{
              'type': 'image_url',
              'image_url': <String, String>{
                'url': 'data:$imageMimeType;base64,${base64Encode(imageBytes)}',
              },
            },
          ];
    final List<Map<String, dynamic>> messages = <Map<String, dynamic>>[
      <String, dynamic>{'role': 'system', 'content': systemPrompt},
      for (final Map<String, String> turn in history)
        <String, dynamic>{
          'role': (turn['role'] == 'model')
              ? 'assistant'
              : (turn['role'] ?? 'user'),
          'content': turn['text'] ?? '',
        },
      <String, dynamic>{'role': 'user', 'content': userContent},
    ];
    final Map<String, dynamic> body = <String, dynamic>{
      'model': model,
      'temperature': temperature,
      'messages': messages,
    };

    final Response<dynamic> res = await _dio.post<dynamic>(
      _endpoint,
      data: body,
      options: Options(
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 15),
        validateStatus: (int? _) => true,
      ),
    );

    final int? code = res.statusCode;
    if (code == 429) throw const GroqRateLimited();
    if (code != 200) throw FormatException('Groq HTTP $code');

    final Map<String, dynamic> json = res.data is String
        ? jsonDecode(res.data as String) as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    final String content = _extractContent(json).trim();
    if (content.isEmpty) {
      throw const FormatException('Groq returned no content');
    }
    return content;
  }

  String _extractContent(Map<String, dynamic> body) {
    final List<dynamic>? choices = body['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) return '';
    final Map<String, dynamic>? message = (choices.first
        as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
    return (message?['content'] as String?) ?? '';
  }
}
