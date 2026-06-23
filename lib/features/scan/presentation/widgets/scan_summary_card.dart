import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/scan_analysis.dart';

class ScanSummaryCard extends StatelessWidget {
  const ScanSummaryCard({super.key, required this.analysis});
  final ScanAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final bool hasRisks = analysis.risks.isNotEmpty;
    final Color bg = analysis.isContract
        ? (hasRisks ? AppColors.brand100 : const Color(0xFFDDF4E8))
        : AppColors.gray100;
    final Color fg = analysis.isContract
        ? (hasRisks ? AppColors.brand : AppColors.success700)
        : AppColors.gray700;
    final IconData icon = analysis.isContract
        ? (hasRisks ? Icons.warning_amber_rounded : Icons.check_circle_rounded)
        : Icons.description_rounded;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: fg, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              analysis.summary,
              style: AppTypography.bodyL.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
