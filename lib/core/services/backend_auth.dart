import '../utils/app_logger.dart';

typedef AuthTokenProvider = Future<String?> Function();

Future<Map<String, String>> backendAuthHeader(
  AuthTokenProvider? provider,
) async {
  try {
    final String? token = await provider?.call();
    if (token == null || token.isEmpty) return const <String, String>{};
    return <String, String>{'Authorization': 'Bearer $token'};
  } catch (e) {
    appLogger.w('🔐 Backend auth token failed: $e');
    return const <String, String>{};
  }
}
