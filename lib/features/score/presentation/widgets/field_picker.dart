import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/field_of_study.dart';

class FieldOfStudyPicker extends StatelessWidget {
  const FieldOfStudyPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final FieldOfStudy value;
  final ValueChanged<FieldOfStudy> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FieldOfStudy.values.map((FieldOfStudy f) {
        final bool active = f == value;
        return GestureDetector(
          onTap: () => onChanged(f),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.brand100 : Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                color: active ? AppColors.brand : AppColors.gray200,
                width: active ? 1.4 : 1,
              ),
            ),
            child: Text(
              f.label,
              style: AppTypography.bodyM.copyWith(
                color: active ? AppColors.brand : AppColors.gray700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
