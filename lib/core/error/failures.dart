import 'package:equatable/equatable.dart';

import 'exceptions.dart' show OtpError;

abstract class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication error']);
}

class OtpFailure extends Failure {
  const OtpFailure(this.error, [super.message = 'Verification failed']);
  final OtpError error;

  @override
  List<Object?> get props => <Object?>[error, message];
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unknown error']);
}
