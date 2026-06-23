import 'package:dio/dio.dart';

import '../config/env.dart';
import '../utils/app_logger.dart';

class EmailService {
  EmailService(this._dio);
  final Dio _dio;

  static const String _endpoint = 'https://api.resend.com/emails';

  bool get isConfigured => Env.resendApiKey.isNotEmpty;

  Future<bool> sendOtp({
    required String email,
    required String code,
    String? name,
  }) async {
    if (!isConfigured) {
      appLogger.w('📧 RESEND_API_KEY missing — DEV OTP for $email: $code');
      return true;
    }
    try {
      final Response<dynamic> res = await _dio.post<dynamic>(
        _endpoint,
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer ${Env.resendApiKey}',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          validateStatus: (int? s) => s != null && s < 500,
        ),
        data: <String, dynamic>{
          'from': Env.resendFrom,
          'to': <String>[email],
          'subject': 'Globaly — verification code: $code',
          'html': _html(code: code, name: name),
          'text': 'Your Globaly verification code is $code. '
              'It expires in 10 minutes.',
        },
      );
      final int status = res.statusCode ?? 0;
      if (status >= 200 && status < 300) return true;
      appLogger.w('📧 Resend failed ($status): ${res.data}');
      return false;
    } catch (e) {
      appLogger.w('📧 Resend error: $e');
      return false;
    }
  }

  String _html({required String code, String? name}) {
    final String hello = (name == null || name.trim().isEmpty)
        ? 'Hello,'
        : 'Hello ${name.trim()},';
    return '''
<!DOCTYPE html>
<html>
  <body style="margin:0;background:#F6F7F9;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
    <div style="max-width:480px;margin:0 auto;padding:32px 24px;">
      <div style="background:#ffffff;border-radius:16px;padding:32px;border:1px solid #E6E8EC;">
        <h1 style="margin:0 0 8px;font-size:20px;color:#0B1220;">Globaly</h1>
        <p style="margin:0 0 24px;color:#4B5360;font-size:15px;">$hello</p>
        <p style="margin:0 0 16px;color:#4B5360;font-size:15px;">
          Use this code to verify your email and finish creating your account:
        </p>
        <div style="font-size:34px;font-weight:700;letter-spacing:10px;color:#DC1F2E;text-align:center;padding:20px 0;background:#FEECEE;border-radius:12px;">
          $code
        </div>
        <p style="margin:20px 0 0;color:#6B7280;font-size:13px;">
          This code expires in 10 minutes. If you didn't request it, you can
          safely ignore this email.
        </p>
      </div>
      <p style="text-align:center;color:#9CA3B0;font-size:12px;margin-top:16px;">
        © Globaly — your guide for moving abroad
      </p>
    </div>
  </body>
</html>''';
  }
}
