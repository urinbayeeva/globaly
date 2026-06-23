import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../domain/entities/destination.dart';
import '../bloc/travel_cubit.dart';

class TravelSection extends StatelessWidget {
  const TravelSection({super.key, required this.country});
  final String country;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TravelCubit>(
      create: (_) => sl<TravelCubit>()..load(country),
      child: BlocBuilder<TravelCubit, TravelState>(
        builder: (BuildContext c, TravelState s) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SectionHeader(
                title: T.of(context, 'travel.places'),
                subtitle: country.isEmpty
                    ? null
                    : T
                        .of(context, 'travel.placesSub')
                        .replaceAll('{0}', country),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 180,
                child: _DestinationsRow(
                  loading: s.loadingDestinations,
                  destinations: s.destinations,
                ),
              ),
              const SizedBox(height: 16),
              _HotelsBanner(country: country),
            ],
          );
        },
      ),
    );
  }
}

class _HotelsBanner extends StatelessWidget {
  const _HotelsBanner({required this.country});
  final String country;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.explorePath(country)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(
                  Icons.hotel_outlined,
                  color: AppColors.brand,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      T.of(context, 'travel.hotels'),
                      style: AppTypography.bodyL.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      country.isEmpty
                          ? T.of(context, 'travel.hotels.browseGeneric')
                          : T
                              .of(context, 'travel.hotels.browse')
                              .replaceAll('{0}', country),
                      style: AppTypography.caption
                          .copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.gray400,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AppTypography.h3),
        if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: AppTypography.caption.copyWith(color: AppColors.gray500),
          ),
        ],
      ],
    );
  }
}

class _DestinationsRow extends StatelessWidget {
  const _DestinationsRow({required this.loading, required this.destinations});
  final bool loading;
  final List<Destination> destinations;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => const _SkeletonCard(width: 220),
      );
    }
    if (destinations.isEmpty) {
      return _Empty(text: T.of(context, 'travel.emptyDestinations'));
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: destinations.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, int i) => _DestinationCard(d: destinations[i]),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.d});
  final Destination d;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
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
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.brand,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      d.name,
                      style: AppTypography.bodyL.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (d.region.isNotEmpty)
                      Text(
                        d.region,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.gray500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              d.summary,
              style: AppTypography.bodyM.copyWith(
                color: AppColors.gray700,
                height: 18 / 13,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (d.bestSeason.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.wb_sunny_outlined,
                  size: 13,
                  color: AppColors.gray500,
                ),
                const SizedBox(width: 4),
                Text(
                  d.bestSeason,
                  style:
                      AppTypography.caption.copyWith(color: AppColors.gray500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({this.width});
  final double? width;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.gray200),
      ),
      child: const AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                ShimmerBox(width: 32, height: 32, radius: 10),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ShimmerBox(),
                      SizedBox(height: 6),
                      ShimmerBox(width: 90, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ShimmerBox(height: 10),
            SizedBox(height: 6),
            ShimmerBox(height: 10),
            SizedBox(height: 6),
            ShimmerBox(width: 140, height: 10),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.travel_explore_outlined,
            color: AppColors.gray400,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyM.copyWith(color: AppColors.gray700),
            ),
          ),
        ],
      ),
    );
  }
}
