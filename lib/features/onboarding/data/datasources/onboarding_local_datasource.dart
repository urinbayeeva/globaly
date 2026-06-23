import 'package:flutter/material.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/storage/prefs.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/onboarding_slide.dart';

abstract class OnboardingLocalDataSource {
  List<OnboardingSlide> getSlides();
  Future<void> markCompleted();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  OnboardingLocalDataSourceImpl(this._prefs);
  final Prefs _prefs;

  @override
  List<OnboardingSlide> getSlides() => <OnboardingSlide>[
        OnboardingSlide(
          title: T.t('onboarding.slide1.title'),
          subtitle: T.t('onboarding.slide1.subtitle'),
          icon: Icons.public_rounded,
          iconColor: AppColors.brand,
          iconBackground: AppColors.brand100,
        ),
        OnboardingSlide(
          title: T.t('onboarding.slide2.title'),
          subtitle: T.t('onboarding.slide2.subtitle'),
          icon: Icons.document_scanner_rounded,
          iconColor: const Color(0xFF1E8A57),
          iconBackground: const Color(0xFFDDF4E8),
        ),
        OnboardingSlide(
          title: T.t('onboarding.slide3.title'),
          subtitle: T.t('onboarding.slide3.subtitle'),
          icon: Icons.auto_awesome_rounded,
          iconColor: const Color(0xFF2D5BD7),
          iconBackground: const Color(0xFFE4ECFE),
        ),
      ];

  @override
  Future<void> markCompleted() => _prefs.setBool(Prefs.kOnboardingDone, true);
}
