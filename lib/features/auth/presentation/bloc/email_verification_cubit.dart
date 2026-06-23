import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/exceptions.dart' show OtpError;
import '../../../../core/error/failures.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

enum VerifyStep { form, code }

class EmailVerifyState extends Equatable {
  const EmailVerifyState({
    this.step = VerifyStep.form,
    this.busy = false,
    this.success = false,
    this.user,
    this.error,
    this.cooldown = 0,
    this.email = '',
  });

  final VerifyStep step;

  final bool busy;

  final bool success;
  final AppUser? user;

  final String? error;

  final int cooldown;

  final String email;

  EmailVerifyState copyWith({
    VerifyStep? step,
    bool? busy,
    bool? success,
    AppUser? user,
    String? error,
    int? cooldown,
    String? email,
  }) =>
      EmailVerifyState(
        step: step ?? this.step,
        busy: busy ?? this.busy,
        success: success ?? this.success,
        user: user ?? this.user,
        error: error,
        cooldown: cooldown ?? this.cooldown,
        email: email ?? this.email,
      );

  @override
  List<Object?> get props =>
      <Object?>[step, busy, success, user, error, cooldown, email];
}

class EmailVerificationCubit extends Cubit<EmailVerifyState> {
  EmailVerificationCubit(this._repo) : super(const EmailVerifyState());

  final AuthRepository _repo;

  String _name = '';
  String _email = '';
  String _password = '';
  Timer? _ticker;

  static const int _resendCooldown = 60;

  Future<void> sendCode({
    required String name,
    required String email,
    required String password,
  }) async {
    _name = name.trim();
    _email = email.trim();
    _password = password;

    emit(state.copyWith(busy: true));
    final Either<Failure, Unit> res =
        await _repo.sendEmailCode(name: _name, email: _email);
    res.fold(
      (Failure f) => emit(state.copyWith(busy: false, error: _message(f))),
      (_) {
        emit(state.copyWith(step: VerifyStep.code, busy: false, email: _email));
        _startCooldown();
      },
    );
  }

  Future<void> resend() async {
    if (state.cooldown > 0 || state.busy) return;
    emit(state.copyWith(busy: true));
    final Either<Failure, Unit> res =
        await _repo.sendEmailCode(name: _name, email: _email);
    res.fold(
      (Failure f) => emit(state.copyWith(busy: false, error: _message(f))),
      (_) {
        emit(state.copyWith(busy: false));
        _startCooldown();
      },
    );
  }

  Future<void> verify(String code) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final Either<Failure, AppUser> res = await _repo.verifyEmailCodeAndSignUp(
      name: _name,
      email: _email,
      password: _password,
      code: code.trim(),
    );
    res.fold(
      (Failure f) => emit(state.copyWith(busy: false, error: _message(f))),
      (AppUser u) => emit(state.copyWith(busy: false, success: true, user: u)),
    );
  }

  void editEmail() {
    _ticker?.cancel();
    emit(const EmailVerifyState());
  }

  void _startCooldown() {
    _ticker?.cancel();
    emit(state.copyWith(cooldown: _resendCooldown));
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      final int next = state.cooldown - 1;
      if (next <= 0) {
        t.cancel();
        emit(state.copyWith(cooldown: 0));
      } else {
        emit(state.copyWith(cooldown: next));
      }
    });
  }

  String _message(Failure f) {
    if (f is OtpFailure) {
      return switch (f.error) {
        OtpError.invalid => T.t('auth.verify.err.invalid'),
        OtpError.expired => T.t('auth.verify.err.expired'),
        OtpError.tooManyAttempts => T.t('auth.verify.err.tooMany'),
        OtpError.sendFailed => T.t('auth.verify.err.sendFailed'),
        OtpError.network => T.t('auth.verify.err.network'),
      };
    }
    return f.message;
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
