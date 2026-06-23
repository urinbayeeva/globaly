import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class IeltsSlider extends StatelessWidget {
  const IeltsSlider({super.key, required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text('IELTS', style: AppTypography.title),
            const Spacer(),
            Text(
              value.toStringAsFixed(1),
              style: AppTypography.h2.copyWith(color: AppColors.brand),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 5,
          max: 9,
          divisions: 8,
          activeColor: AppColors.brand,
          inactiveColor: AppColors.gray200,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class SatSlider extends StatelessWidget {
  const SatSlider({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text('SAT', style: AppTypography.title),
            const Spacer(),
            Text(
              '$value',
              style: AppTypography.h2.copyWith(color: AppColors.brand),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 800,
          max: 1600,
          divisions: 16,
          activeColor: AppColors.brand,
          inactiveColor: AppColors.gray200,
          onChanged: (double v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
