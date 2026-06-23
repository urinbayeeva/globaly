import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/education.dart';

class EducationLevelPicker extends StatelessWidget {
  const EducationLevelPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final EducationLevel value;
  final ValueChanged<EducationLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: EducationLevel.values.map((EducationLevel ed) {
        final bool active = ed == value;
        return GestureDetector(
          onTap: () => onChanged(ed),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.brand : Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                color: active ? AppColors.brand : AppColors.gray200,
              ),
            ),
            child: Text(
              ed.label,
              style: AppTypography.bodyM.copyWith(
                color: active ? Colors.white : AppColors.gray700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
