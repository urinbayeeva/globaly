import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, success, failure }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? error;

  AuthState copyWith({AuthStatus? status, AppUser? user, String? error}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
      );

  @override
  List<Object?> get props => <Object?>[status, user, error];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(const AuthState());

  final AuthRepository _repo;

  Future<void> signIn(String email, String password) =>
      _run(() => _repo.signIn(email, password));

  Future<void> signUp(String name, String email, String password) =>
      _run(() => _repo.signUp(name, email, password));

  Future<void> guest() => _run(_repo.signInAsGuest);

  Future<void> signInWithGoogle() => _runSocial(_repo.signInWithGoogle);

  Future<void> signInWithApple() => _runSocial(_repo.signInWithApple);

  Future<void> signOut() async {
    await _repo.signOut();
    emit(const AuthState());
  }

  Future<void> _runSocial(
    Future<Either<Failure, AppUser?>> Function() action,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final Either<Failure, AppUser?> res = await action();
    res.fold(
      (Failure f) =>
          emit(state.copyWith(status: AuthStatus.failure, error: f.message)),
      (AppUser? u) => emit(
        u == null
            ? const AuthState()
            : state.copyWith(status: AuthStatus.success, user: u),
      ),
    );
  }

  Future<void> _run(
    Future<Either<Failure, AppUser>> Function() action,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final Either<Failure, AppUser> res = await action();
    res.fold(
      (Failure f) =>
          emit(state.copyWith(status: AuthStatus.failure, error: f.message)),
      (AppUser u) => emit(state.copyWith(status: AuthStatus.success, user: u)),
    );
  }
}
