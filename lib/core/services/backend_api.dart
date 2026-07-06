import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/env.dart';
import '../di/injector.dart';
import '../storage/prefs.dart';
import 'backend_auth.dart';

class MissingBackendUrl implements Exception {
  const MissingBackendUrl();
  @override
  String toString() => 'BACKEND_URL not provided at build time';
}

class AiRateLimited implements Exception {
  const AiRateLimited(this.retryAfter);
  final Duration retryAfter;
  @override
  String toString() => 'AI rate-limited, retry after ${retryAfter.inSeconds}s';
}

class AiUnavailable implements Exception {
  const AiUnavailable(this.statusCode);
  final int statusCode;
  @override
  String toString() => 'Backend HTTP $statusCode';
}

class BackendApi {
  BackendApi(this._dio, {AuthTokenProvider? tokenProvider})
      : _tokenProvider = tokenProvider;

  final Dio _dio;
  final AuthTokenProvider? _tokenProvider;

  bool get isConfigured => Env.backendUrl.isNotEmpty;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    if (!isConfigured) throw const MissingBackendUrl();
    final Response<dynamic> res = await _dio.post<dynamic>(
      '${Env.backendUrl}$path',
      data: <String, dynamic>{...body, 'locale': _locale()},
      options: Options(
        headers: <String, String>{
          'Content-Type': 'application/json',
          ...await backendAuthHeader(_tokenProvider),
        },
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
        validateStatus: (int? _) => true,
      ),
    );
    final int code = res.statusCode ?? 0;
    if (code == 429) throw AiRateLimited(_retryAfter(res));
    if (code != 200) throw AiUnavailable(code);
    return res.data is String
        ? jsonDecode(res.data as String) as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
  }

  Duration _retryAfter(Response<dynamic> res) {
    final int? seconds = int.tryParse(res.headers.value('retry-after') ?? '');
    return Duration(seconds: seconds ?? 60);
  }

  String _locale() {
    try {
      return sl<Prefs>().getString(Prefs.kAppLocale) ?? 'en';
    } catch (_) {
      return 'en';
    }
  }
}
