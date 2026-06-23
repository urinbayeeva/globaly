import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/pill.dart';
import '../../domain/entities/scan_analysis.dart';

class DetectedRiskCard extends StatelessWidget {
  const DetectedRiskCard({super.key, required this.risk});
  final DetectedRisk risk;

  PillTone get _pillTone {
    switch (risk.severity) {
      case RiskSeverity.dangerous:
        return PillTone.red;
      case RiskSeverity.warning:
        return PillTone.amber;
      case RiskSeverity.notice:
        return PillTone.gray;
    }
  }

  String get _pillText {
    switch (risk.severity) {
      case RiskSeverity.dangerous:
        return 'Dangerous';
      case RiskSeverity.warning:
        return 'Warning';
      case RiskSeverity.notice:
        return 'Notice';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  risk.title,
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Pill(label: _pillText, tone: _pillTone),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.alert100,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              '"${risk.quote}"',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: AppColors.gray700,
                height: 18 / 13,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            risk.explanation,
            style: AppTypography.bodyL
                .copyWith(color: AppColors.gray800, height: 20 / 14),
          ),
        ],
      ),
    );
  }
}
