import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AppUser>> signIn(String email, String password);

  Future<Either<Failure, AppUser>> signUp(
    String name,
    String email,
    String password,
  );

  Future<Either<Failure, AppUser>> signInAsGuest();

  Future<Either<Failure, AppUser?>> signInWithGoogle();
  Future<Either<Failure, AppUser?>> signInWithApple();

  Future<Either<Failure, Unit>> sendEmailCode({
    required String name,
    required String email,
  });

  Future<Either<Failure, AppUser>> verifyEmailCodeAndSignUp({
    required String name,
    required String email,
    required String password,
    required String code,
  });

  Future<void> signOut();
  AppUser? currentUser();
}
