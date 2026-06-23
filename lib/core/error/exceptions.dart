class ServerException implements Exception {
  const ServerException([this.message = 'Server error']);
  final String message;
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection']);
  final String message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Cache error']);
  final String message;
}

class AuthException implements Exception {
  const AuthException([this.message = 'Authentication error']);
  final String message;
}

class AuthCancelledException implements Exception {
  const AuthCancelledException();
}

enum OtpError { invalid, expired, tooManyAttempts, sendFailed, network }

class OtpException implements Exception {
  const OtpException(this.error);
  final OtpError error;
}
