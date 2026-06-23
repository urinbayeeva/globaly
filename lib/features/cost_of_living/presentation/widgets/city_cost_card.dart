import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/city_cost.dart';

class CityCostCard extends StatelessWidget {
  const CityCostCard({super.key, required this.cost});
  final CityCost cost;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(cost.flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(cost.city, style: AppTypography.h3),
                    Text(
                      cost.country,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '${cost.total} ${cost.currency}',
                    style: AppTypography.h3.copyWith(color: AppColors.brand),
                  ),
                  Text(
                    'per month',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.gray500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _CostBreak(label: 'Rent', value: cost.rentMonthly),
              _CostBreak(label: 'Food', value: cost.foodMonthly),
              _CostBreak(label: 'Transit', value: cost.transportMonthly),
              _CostBreak(label: 'Misc', value: cost.miscMonthly),
            ],
          ),
        ],
      ),
    );
  }
}

class _CostBreak extends StatelessWidget {
  const _CostBreak({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            '$value',
            style: AppTypography.title.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}
