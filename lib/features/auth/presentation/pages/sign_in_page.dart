import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/extensions/context_x.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_cubit.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/social_auth_buttons.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => sl<AuthCubit>(),
      child: const _SignInView(),
    );
  }
}

class _SignInView extends StatefulWidget {
  const _SignInView();
  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onSuccess() => context.go(AppRoutes.countryPicker);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (BuildContext c, AuthState s) {
            if (s.status == AuthStatus.success) _onSuccess();
            if (s.status == AuthStatus.failure && s.error != null) {
              context.showSnack(s.error!, error: true);
            }
          },
          builder: (BuildContext c, AuthState s) {
            final bool loading = s.status == AuthStatus.loading;
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              children: <Widget>[
                AuthBrandHeader(
                  title: T.of(context, 'auth.signIn.title'),
                  subtitle: T.of(context, 'auth.signIn.subtitle'),
                ),
                const SizedBox(height: 28),
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
                  hint: '••••••••',
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
                  label: T.of(context, 'auth.signIn.button'),
                  loading: loading,
                  onPressed: loading
                      ? null
                      : () => c.read<AuthCubit>().signIn(
                            _email.text,
                            _password.text,
                          ),
                ),
                const SizedBox(height: 22),
                SocialAuthButtons(
                  enabled: !loading,
                  onGoogle: c.read<AuthCubit>().signInWithGoogle,
                  onApple: c.read<AuthCubit>().signInWithApple,
                ),
                const SizedBox(height: 22),
                AppButton(
                  label: T.of(context, 'auth.continueAsGuest'),
                  variant: AppButtonVariant.secondary,
                  onPressed: loading ? null : c.read<AuthCubit>().guest,
                ),
                const SizedBox(height: 18),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.signUp),
                    child: Text(
                      T.of(context, 'auth.signIn.switch'),
                      style: AppTypography.bodyM.copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
