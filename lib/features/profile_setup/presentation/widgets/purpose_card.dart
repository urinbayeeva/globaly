import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_badge.dart';
import '../../domain/entities/purpose.dart';

class PurposeCard extends StatelessWidget {
  const PurposeCard({
    super.key,
    required this.purpose,
    required this.selected,
    required this.onTap,
  });

  final Purpose purpose;
  final bool selected;
  final VoidCallback onTap;

  IconData _iconFor(Purpose p) {
    switch (p) {
      case Purpose.study:
        return PhosphorIconsDuotone.graduationCap;
      case Purpose.work:
        return PhosphorIconsDuotone.briefcase;
      case Purpose.family:
        return PhosphorIconsDuotone.heart;
      case Purpose.tourism:
        return PhosphorIconsDuotone.airplaneTakeoff;
      case Purpose.business:
        return PhosphorIconsDuotone.buildings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brand100 : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.gray200,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              IconBadge(icon: _iconFor(purpose)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      T.of(context, 'purpose.${purpose.code}'),
                      style: AppTypography.title,
                    ),
                    Text(
                      T.of(context, 'purpose.${purpose.code}.desc'),
                      style: AppTypography.caption
                          .copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? PhosphorIconsFill.checkCircle
                    : PhosphorIconsRegular.circle,
                color: selected ? AppColors.brand : AppColors.gray300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
