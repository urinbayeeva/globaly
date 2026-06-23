import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/city_cost_db.dart';
import '../../domain/city_cost.dart';
import '../widgets/city_cost_card.dart';

class CostOfLivingPage extends StatelessWidget {
  const CostOfLivingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<CityCost> cities = List<CityCost>.of(CityCostDb().all())
      ..sort((CityCost a, CityCost b) => a.total.compareTo(b.total));
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const Text('Cost of living', style: AppTypography.h2),
              ],
            ),
            const SizedBox(height: 8),
            _Banner(),
            const SizedBox(height: 18),
            ...cities.map((CityCost c) => CityCostCard(cost: c)),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.brandSolid,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.attach_money_rounded,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'What it really costs',
                  style: AppTypography.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Average monthly spend for one person, in USD. Tap a city for details.',
                  style: AppTypography.bodyM
                      .copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
