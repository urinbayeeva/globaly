import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/theme/app_typography.dart';

class NextBestActionCard extends StatelessWidget {
  const NextBestActionCard({
    super.key,
    required this.stepLabel,
    required this.title,
    required this.timeEstimate,
    this.onTap,
  });

  final String stepLabel;
  final String title;
  final String timeEstimate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: AppColors.brandSolid,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  stepLabel.toUpperCase(),
                  style: AppTypography.micro.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeEstimate,
                  style: AppTypography.bodyM.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withValues(alpha: 0.95),
            size: 22,
          ),
        ],
      ),
    );
  }
}
