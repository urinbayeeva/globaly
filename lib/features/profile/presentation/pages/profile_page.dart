import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/i18n/locale_notifier.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/storage/prefs.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_topbar.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../core/widgets/sheet_grabber.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../profile_setup/data/datasources/countries_db.dart';
import '../../../profile_setup/domain/entities/country.dart';
import '../widgets/profile_header.dart';
import '../widgets/settings_tile.dart';

enum AppLanguage {
  english('en', 'English', '🇬🇧', 'English'),
  russian('ru', 'Русский', '🇷🇺', 'Russian'),
  uzbek('uz', "O'zbek", '🇺🇿', 'Uzbek');

  const AppLanguage(this.code, this.label, this.flag, this.englishName);
  final String code;

  final String label;

  final String flag;

  final String englishName;

  static AppLanguage fromCode(String? code) {
    for (final AppLanguage l in AppLanguage.values) {
      if (l.code == code) return l;
    }
    return AppLanguage.english;
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late AppLanguage _language;
  late bool _notifications;

  @override
  void initState() {
    super.initState();
    final Prefs prefs = sl<Prefs>();
    _language = AppLanguage.fromCode(prefs.getString(Prefs.kAppLocale));
    _notifications = prefs.getBool(Prefs.kNotifications) ?? true;
  }

  Future<void> _pickLanguage() async {
    final AppLanguage? picked = await showModalBottomSheet<AppLanguage>(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => _LanguageSheet(current: _language),
    );
    if (picked == null || picked == _language) return;

    await sl<LocaleNotifier>().setLocale(picked.code);
    if (!mounted) return;
    setState(() => _language = picked);
  }

  Future<void> _toggleNotifications(bool value) async {
    await sl<Prefs>().setBool(Prefs.kNotifications, value);
    final NotificationService notifications = sl<NotificationService>();
    if (value) {
      await notifications.requestPermission();
      await notifications.show(
        title: T.t('notif.onTitle'),
        body: T.t('notif.onBody'),
      );
    } else {
      await notifications.cancelAll();
    }
    if (!mounted) return;
    setState(() => _notifications = value);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => sl<AuthCubit>(),
      child: Container(
        color: AppColors.appBg,
        child: SafeArea(
          bottom: false,
          child: _ProfileBody(
            language: _language,
            notifications: _notifications,
            onPickLanguage: _pickLanguage,
            onToggleNotifications: _toggleNotifications,
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.language,
    required this.notifications,
    required this.onPickLanguage,
    required this.onToggleNotifications,
  });

  final AppLanguage language;
  final bool notifications;
  final VoidCallback onPickLanguage;
  final ValueChanged<bool> onToggleNotifications;

  @override
  Widget build(BuildContext context) {
    AppUser? user;
    try {
      user = sl<AuthRepository>().currentUser();
    } catch (_) {
      user = null;
    }
    final String name = (user?.name != null && user!.name!.isNotEmpty)
        ? user.name!
        : T.of(context, 'profile.guest');
    final String email = user?.email ?? '';

    final Prefs prefs = sl<Prefs>();
    final String? destCode = prefs.getString(Prefs.kDestinationCountry);
    final Country? destCountry =
        destCode == null ? null : sl<CountriesDb>().byCode(destCode);
    final String location = email.isNotEmpty
        ? email
        : (destCountry == null ? '' : 'Going to ${destCountry.name}');

    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: <Widget>[
        AppTopbar(title: T.of(context, 'profile.title')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ProfileHeader(
            name: name,
            location: location,
            verified: user != null && !(user.isGuest),
          ),
        ),
        const SizedBox(height: 22),
        SectionLabel(
          T.of(context, 'profile.app'),
          padding: SectionLabel.standardPadding,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: <Widget>[
                SettingsTile.value(
                  icon: PhosphorIconsRegular.translate,
                  label: T.of(context, 'profile.language'),
                  value: language.label,
                  onTap: onPickLanguage,
                ),
                SettingsTile.toggle(
                  icon: PhosphorIconsRegular.bell,
                  label: T.of(context, 'profile.notifications'),
                  on: notifications,
                  onToggle: onToggleNotifications,
                  last: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SectionLabel(
          T.of(context, 'profile.account'),
          padding: SectionLabel.standardPadding,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: <Widget>[
                SettingsTile.value(
                  icon: PhosphorIconsRegular.globe,
                  label: T.of(context, 'profile.destination'),
                  value: destCountry?.name ?? 'Pick',
                  onTap: () => context.push(AppRoutes.countryPicker),
                ),
                SettingsTile.value(
                  icon: PhosphorIconsRegular.flag,
                  label: T.of(context, 'profile.purpose'),
                  value: 'Edit',
                  onTap: () => context.push(AppRoutes.purposePicker),
                ),
                Builder(
                  builder: (BuildContext ctx) {
                    return SettingsTile.value(
                      icon: PhosphorIconsRegular.signOut,
                      label: T.of(context, 'profile.signOut'),
                      value: '',
                      last: true,
                      onTap: () async {
                        await ctx.read<AuthCubit>().signOut();
                        if (ctx.mounted) ctx.go(AppRoutes.signIn);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: Text(
            'Globaly v1.0',
            style: AppTypography.caption.copyWith(color: AppColors.gray400),
          ),
        ),
      ],
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.current});
  final AppLanguage current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.xxl),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SheetGrabber(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  T.of(context, 'profile.pickLanguage'),
                  style: AppTypography.h3.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (final AppLanguage l in AppLanguage.values) ...<Widget>[
              _LanguageRow(
                language: l,
                selected: l == current,
                onTap: () => Navigator.of(context).pop(l),
              ),
              if (l != AppLanguage.values.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.selected,
    required this.onTap,
  });
  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brand100 : AppColors.appBg,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: selected ? AppColors.brand200 : Colors.transparent,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  language.flag,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      language.label,
                      style: AppTypography.bodyL.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      language.englishName,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.brand : AppColors.gray300,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
