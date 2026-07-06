import 'package:dio/dio.dart';

import '../config/env.dart';
import '../utils/app_logger.dart';
import 'backend_auth.dart';

class EmailService {
  EmailService(this._dio, {AuthTokenProvider? tokenProvider})
      : _tokenProvider = tokenProvider;

  final Dio _dio;
  final AuthTokenProvider? _tokenProvider;

  bool get isConfigured => Env.backendUrl.isNotEmpty;

  Future<bool> sendOtp({
    required String email,
    required String code,
    String? name,
  }) async {
    if (!isConfigured) {
      appLogger.w('📧 BACKEND_URL missing — DEV OTP for $email: $code');
      return true;
    }
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        '${Env.backendUrl}/v1/email/otp',
        options: Options(
          headers: <String, String>{
            'Content-Type': 'application/json',
            ...await backendAuthHeader(_tokenProvider),
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          validateStatus: (int? s) => s != null && s < 500,
        ),
        data: <String, dynamic>{
          'email': email,
          'code': code,
          if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        },
      );
      final int status = res.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        final dynamic data = res.data;
        return data is Map<String, dynamic> ? data['sent'] == true : true;
      }
      appLogger.w('📧 OTP send failed ($status): ${res.data}');
      return false;
    } catch (e) {
      appLogger.w('📧 OTP send error: $e');
      return false;
    }
  }
}
