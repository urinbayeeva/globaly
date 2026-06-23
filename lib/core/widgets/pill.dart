import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum PillTone { brand, gray, green, amber, red }

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.tone = PillTone.brand,
    this.showDot = true,
  });

  final String label;
  final PillTone tone;
  final bool showDot;

  ({Color bg, Color fg, Color dot}) get _palette {
    switch (tone) {
      case PillTone.brand:
        return (
          bg: AppColors.brand100,
          fg: AppColors.brand700,
          dot: AppColors.brand
        );
      case PillTone.gray:
        return (
          bg: AppColors.gray100,
          fg: AppColors.gray700,
          dot: AppColors.gray400
        );
      case PillTone.green:
        return (
          bg: AppColors.success100,
          fg: AppColors.success700,
          dot: AppColors.success
        );
      case PillTone.amber:
        return (
          bg: AppColors.warning100,
          fg: AppColors.warning700,
          dot: AppColors.warning
        );
      case PillTone.red:
        return (
          bg: AppColors.alert100,
          fg: AppColors.alert700,
          dot: AppColors.alert
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (showDot) ...<Widget>[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: p.dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: AppTypography.micro.copyWith(
              color: p.fg,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
