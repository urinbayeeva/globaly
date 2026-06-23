import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SuggestedChips extends StatelessWidget {
  const SuggestedChips({super.key, required this.prompts, required this.onTap});
  final List<String> prompts;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'SUGGESTED',
          style: AppTypography.micro.copyWith(
            color: AppColors.gray500,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: prompts.map((String p) {
            return GestureDetector(
              onTap: () => onTap(p),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.gray200),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  p,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.brand700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
