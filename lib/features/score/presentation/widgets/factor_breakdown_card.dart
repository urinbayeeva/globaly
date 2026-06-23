import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pill.dart';

class FactorRow {
  const FactorRow({
    required this.label,
    required this.value,
    required this.strong,
  });
  final String label;
  final String value;
  final bool strong;
}

class FactorBreakdownCard extends StatelessWidget {
  const FactorBreakdownCard({super.key, required this.rows});
  final List<FactorRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A0D1424),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: List<Widget>.generate(rows.length, (int i) {
          final bool last = i == rows.length - 1;
          final FactorRow r = rows[i];
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: last
                    ? BorderSide.none
                    : const BorderSide(color: AppColors.gray100),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    r.label,
                    style:
                        AppTypography.bodyL.copyWith(color: AppColors.gray800),
                  ),
                ),
                Text(
                  r.value,
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                    fontFeatures: AppTypography.tabular,
                  ),
                ),
                const SizedBox(width: 10),
                Pill(
                  label: r.strong ? 'Strong' : 'Improve',
                  tone: r.strong ? PillTone.green : PillTone.amber,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
