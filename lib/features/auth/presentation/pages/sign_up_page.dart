import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/email_verification_cubit.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/otp_input.dart';
import '../widgets/social_auth_buttons.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<AuthCubit>(create: (_) => sl<AuthCubit>()),
        BlocProvider<EmailVerificationCubit>(
          create: (_) => sl<EmailVerificationCubit>(),
        ),
      ],
      child: const _SignUpView(),
    );
  }
}

class _SignUpView extends StatefulWidget {
  const _SignUpView();
  @override
  State<_SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<_SignUpView> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final GlobalKey<OtpInputState> _otpKey = GlobalKey<OtpInputState>();
  String _code = '';
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onSuccess() => context.go(AppRoutes.countryPicker);

  void _submitForm() {
    final String name = _name.text.trim();
    final String? emailErr = InputValidators.email(_email.text.trim());
    final String? passErr = InputValidators.password(_password.text);
    if (name.isEmpty) {
      context.showSnack(T.of(context, 'auth.err.name'), error: true);
      return;
    }
    if (emailErr != null) {
      context.showSnack(T.of(context, 'auth.err.email'), error: true);
      return;
    }
    if (passErr != null) {
      context.showSnack(T.of(context, 'auth.err.password'), error: true);
      return;
    }
    context.read<EmailVerificationCubit>().sendCode(
          name: name,
          email: _email.text.trim(),
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: MultiBlocListener(
          listeners: <BlocListener<dynamic, dynamic>>[
            BlocListener<AuthCubit, AuthState>(
              listener: (BuildContext c, AuthState s) {
                if (s.status == AuthStatus.success) _onSuccess();
                if (s.status == AuthStatus.failure && s.error != null) {
                  c.showSnack(s.error!, error: true);
                }
              },
            ),
            BlocListener<EmailVerificationCubit, EmailVerifyState>(
              listenWhen: (EmailVerifyState p, EmailVerifyState n) =>
                  p.success != n.success || p.error != n.error,
              listener: (BuildContext c, EmailVerifyState s) {
                if (s.success) {
                  _onSuccess();
                } else if (s.error != null) {
                  c.showSnack(s.error!, error: true);
                  _otpKey.currentState?.clear();
                }
              },
            ),
          ],
          child: BlocBuilder<EmailVerificationCubit, EmailVerifyState>(
            builder: (BuildContext c, EmailVerifyState s) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: s.step == VerifyStep.form
                    ? _formStep(c, s)
                    : _codeStep(c, s),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _formStep(BuildContext c, EmailVerifyState s) {
    final bool authLoading =
        context.watch<AuthCubit>().state.status == AuthStatus.loading;
    final bool busy = s.busy || authLoading;
    return ListView(
      key: const ValueKey<String>('form'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: <Widget>[
        AuthBrandHeader(
          title: T.of(context, 'auth.signUp.title'),
          subtitle: T.of(context, 'auth.signUp.subtitle'),
        ),
        const SizedBox(height: 28),
        AppTextField(
          controller: _name,
          label: T.of(context, 'auth.name'),
          hint: 'Jane Doe',
          prefixIcon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _email,
          label: T.of(context, 'auth.email'),
          hint: 'you@example.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _password,
          label: T.of(context, 'auth.password'),
          hint: '8+',
          obscure: _obscure,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.gray500,
              size: 20,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: T.of(context, 'auth.signUp.sendCode'),
          loading: s.busy,
          onPressed: busy ? null : _submitForm,
        ),
        const SizedBox(height: 22),
        SocialAuthButtons(
          enabled: !busy,
          onGoogle: c.read<AuthCubit>().signInWithGoogle,
          onApple: c.read<AuthCubit>().signInWithApple,
        ),
        const SizedBox(height: 22),
        Center(
          child: GestureDetector(
            onTap: () => context.go(AppRoutes.signIn),
            child: Text(
              T.of(context, 'auth.signUp.switch'),
              style: AppTypography.bodyM.copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _codeStep(BuildContext c, EmailVerifyState s) {
    final bool canResend = s.cooldown == 0 && !s.busy;
    return ListView(
      key: const ValueKey<String>('code'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: <Widget>[
        AuthBrandHeader(
          title: T.of(context, 'auth.verify.title'),
          subtitle: T.f(context, 'auth.verify.subtitle', s.email),
        ),
        const SizedBox(height: 32),
        OtpInput(
          key: _otpKey,
          enabled: !s.busy,
          onChanged: (String v) => _code = v,
          onCompleted: (String v) {
            _code = v;
            c.read<EmailVerificationCubit>().verify(v);
          },
        ),
        const SizedBox(height: 24),
        AppButton(
          label: T.of(context, 'auth.verify.button'),
          loading: s.busy,
          onPressed: s.busy
              ? null
              : () => c.read<EmailVerificationCubit>().verify(_code),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed:
                canResend ? c.read<EmailVerificationCubit>().resend : null,
            child: Text(
              s.cooldown > 0
                  ? T.f(context, 'auth.verify.resendIn', '${s.cooldown}')
                  : T.of(context, 'auth.verify.resend'),
              style: AppTypography.bodyM.copyWith(
                color: canResend ? AppColors.brand : AppColors.gray400,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: () {
              _code = '';
              c.read<EmailVerificationCubit>().editEmail();
            },
            child: Text(
              T.of(context, 'auth.verify.changeEmail'),
              style: AppTypography.bodyM.copyWith(color: AppColors.gray500),
            ),
          ),
        ),
      ],
    );
  }
}
