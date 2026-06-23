import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/email_verification_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._ds, this._verification, this._secure);
  final AuthRemoteDataSource _ds;
  final EmailVerificationDataSource _verification;
  final SecureStorage _secure;

  @override
  Future<Either<Failure, AppUser>> signIn(String email, String password) async {
    try {
      final AppUser u = await _ds.signIn(email, password);
      await _secure.write(SecureStorage.kAuthToken, u.id);
      return Right<Failure, AppUser>(u);
    } on AuthException catch (e) {
      return Left<Failure, AppUser>(AuthFailure(e.message));
    } catch (e) {
      return Left<Failure, AppUser>(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> signUp(
    String name,
    String email,
    String password,
  ) async {
    try {
      final AppUser u = await _ds.signUp(email, password, name);
      await _secure.write(SecureStorage.kAuthToken, u.id);
      return Right<Failure, AppUser>(u);
    } on AuthException catch (e) {
      return Left<Failure, AppUser>(AuthFailure(e.message));
    } catch (e) {
      return Left<Failure, AppUser>(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser?>> signInWithGoogle() =>
      _social(_ds.signInWithGoogle);

  @override
  Future<Either<Failure, AppUser?>> signInWithApple() =>
      _social(_ds.signInWithApple);

  Future<Either<Failure, AppUser?>> _social(
    Future<AppUser?> Function() action,
  ) async {
    try {
      final AppUser? u = await action();
      if (u == null) return const Right<Failure, AppUser?>(null);
      await _secure.write(SecureStorage.kAuthToken, u.id);
      return Right<Failure, AppUser?>(u);
    } on AuthException catch (e) {
      return Left<Failure, AppUser?>(AuthFailure(e.message));
    } catch (e) {
      return Left<Failure, AppUser?>(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendEmailCode({
    required String name,
    required String email,
  }) async {
    try {
      await _verification.sendCode(name: name, email: email);
      return const Right<Failure, Unit>(unit);
    } on OtpException catch (e) {
      return Left<Failure, Unit>(OtpFailure(e.error));
    } catch (e) {
      return Left<Failure, Unit>(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> verifyEmailCodeAndSignUp({
    required String name,
    required String email,
    required String password,
    required String code,
  }) async {
    try {
      await _verification.verifyCode(email: email, code: code);
    } on OtpException catch (e) {
      return Left<Failure, AppUser>(OtpFailure(e.error));
    } catch (e) {
      return Left<Failure, AppUser>(UnknownFailure(e.toString()));
    }

    return signUp(name, email, password);
  }

  @override
  Future<Either<Failure, AppUser>> signInAsGuest() async {
    final AppUser u = AppUser.guest();
    await _secure.write(SecureStorage.kAuthToken, u.id);
    return Right<Failure, AppUser>(u);
  }

  @override
  Future<void> signOut() async {
    await _secure.clear();
    await _ds.signOut();
  }

  @override
  AppUser? currentUser() => _ds.currentUser();
}
