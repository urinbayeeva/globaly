import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class OnboardingSlide extends Equatable {
  const OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  @override
  List<Object?> get props =>
      <Object?>[title, subtitle, icon, iconColor, iconBackground];
}
