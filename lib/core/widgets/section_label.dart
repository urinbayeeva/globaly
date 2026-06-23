import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.padding});

  static const EdgeInsets standardPadding = EdgeInsets.fromLTRB(20, 0, 20, 10);

  final String text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final Widget label = Text(
      text.toUpperCase(),
      style: AppTypography.micro.copyWith(
        color: AppColors.gray500,
        fontSize: 13,
        letterSpacing: 0.4,
      ),
    );
    if (padding == null) return label;
    return Padding(padding: padding!, child: label);
  }
}
