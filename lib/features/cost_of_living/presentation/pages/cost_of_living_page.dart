import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/storage/prefs.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/async_state_view.dart';
import '../../../profile_setup/data/datasources/countries_db.dart';
import '../../../profile_setup/domain/entities/country.dart';
import '../bloc/cost_cubit.dart';
import '../widgets/city_cost_card.dart';

class CostOfLivingPage extends StatelessWidget {
  const CostOfLivingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? code = sl<Prefs>().getString(Prefs.kDestinationCountry);
    final Country? country =
        code == null ? null : sl<CountriesDb>().byCode(code);

    return BlocProvider<CostCubit>(
      create: (_) => sl<CostCubit>()
        ..load(
          country: country?.name ?? '',
          flag: country?.flagEmoji ?? '🌍',
        ),
      child: _CostView(country: country),
    );
  }
}

class _CostView extends StatelessWidget {
  const _CostView({required this.country});

  final Country? country;

  void _retry(BuildContext context) => context.read<CostCubit>().load(
        country: country?.name ?? '',
        flag: country?.flagEmoji ?? '🌍',
      );

  @override
  Widget build(BuildContext context) {
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
            _Banner(country: country?.name ?? ''),
            const SizedBox(height: 18),
            BlocBuilder<CostCubit, CostState>(
              builder: (BuildContext context, CostState state) {
                return AsyncStateView<void>(
                  isLoading: state.loading,
                  error: state.error,
                  isEmpty: state.cities.isEmpty,
                  onRetry: () => _retry(context),
                  emptyLabel: 'No cost data yet.',
                  loadingPlaceholder: (_) => const _CostSkeleton(),
                  builder: (_) => Column(
                    children:
                        state.cities.map((c) => CityCostCard(cost: c)).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.country});

  final String country;

  @override
  Widget build(BuildContext context) {
    final String subtitle = country.isEmpty
        ? 'Average monthly spend for one person, in USD.'
        : 'Estimated monthly spend in $country for one person, in USD.';
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
                  subtitle,
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

class _CostSkeleton extends StatelessWidget {
  const _CostSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        ShimmerCard(height: 120),
        SizedBox(height: 12),
        ShimmerCard(height: 120),
        SizedBox(height: 12),
        ShimmerCard(height: 120),
      ],
    );
  }
}
