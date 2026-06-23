import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../domain/entities/hotel.dart';
import '../bloc/travel_cubit.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key, required this.country});
  final String country;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TravelCubit>(
      create: (_) => sl<TravelCubit>()..load(country),
      child: Scaffold(
        backgroundColor: AppColors.appBg,
        appBar: AppBar(
          backgroundColor: AppColors.appBg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.ink,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Explore',
                style: AppTypography.caption
                    .copyWith(color: AppColors.gray500, fontSize: 11),
              ),
              Text(
                country.isEmpty ? 'Hotels' : country,
                style: AppTypography.bodyL.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          titleSpacing: 0,
        ),
        body: BlocBuilder<TravelCubit, TravelState>(
          builder: (BuildContext c, TravelState s) {
            if (s.loadingHotels) return const _GridSkeleton();
            if (s.hotels.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No hotels to show yet.',
                    style:
                        AppTypography.bodyM.copyWith(color: AppColors.gray700),
                  ),
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: s.hotels.length,
              itemBuilder: (_, int i) => _HotelTile(hotel: s.hotels[i]),
            );
          },
        ),
      ),
    );
  }
}

class _HotelTile extends StatelessWidget {
  const _HotelTile({required this.hotel});
  final Hotel hotel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showSheet(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 16 / 11,
                child: _HotelImage(hotel: hotel),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      hotel.name,
                      style: AppTypography.bodyL.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.place_outlined,
                          size: 11,
                          color: AppColors.gray500,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            hotel.city,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.gray500,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        if (hotel.priceUsdPerNight > 0)
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: <InlineSpan>[
                                  TextSpan(
                                    text: '\$${hotel.priceUsdPerNight}',
                                    style: AppTypography.h3.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' /night',
                                    style: AppTypography.micro.copyWith(
                                      color: AppColors.gray500,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        if (hotel.rating > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              hotel.rating.toStringAsFixed(1),
                              style: AppTypography.micro.copyWith(
                                color: AppColors.success700,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HotelSheet(hotel: hotel),
    );
  }
}

class _HotelImage extends StatelessWidget {
  const _HotelImage({required this.hotel});
  final Hotel hotel;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFEECEE), Color(0xFFFCD0D5)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.hotel_rounded,
          color: AppColors.brand,
          size: 40,
        ),
      ),
    );
    if (hotel.imageUrl.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: hotel.imageUrl,
      fit: BoxFit.cover,
      memCacheWidth: 600,
      placeholder: (_, __) => Container(color: AppColors.gray100),
      errorWidget: (_, __, ___) => fallback,
    );
  }
}

class _HotelSheet extends StatelessWidget {
  const _HotelSheet({required this.hotel});
  final Hotel hotel;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ScrollController controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: EdgeInsets.zero,
            children: <Widget>[
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: _HotelImage(hotel: hotel),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      hotel.name,
                      style: AppTypography.h2.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: AppColors.gray500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hotel.city,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.gray500),
                        ),
                        if (hotel.stars > 0) ...<Widget>[
                          const SizedBox(width: 10),
                          for (int i = 0; i < hotel.stars; i++)
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: AppColors.warning,
                            ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (hotel.priceUsdPerNight > 0 || hotel.rating > 0)
                      Row(
                        children: <Widget>[
                          if (hotel.priceUsdPerNight > 0)
                            Expanded(
                              child: _StatTile(
                                label: 'PER NIGHT',
                                value: '\$${hotel.priceUsdPerNight}',
                              ),
                            ),
                          if (hotel.priceUsdPerNight > 0 && hotel.rating > 0)
                            const SizedBox(width: 10),
                          if (hotel.rating > 0)
                            Expanded(
                              child: _StatTile(
                                label: 'GUEST RATING',
                                value: '${hotel.rating.toStringAsFixed(1)}/10',
                              ),
                            ),
                        ],
                      ),
                    if (hotel.summary.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 18),
                      Text(
                        hotel.summary,
                        style: AppTypography.bodyL.copyWith(
                          color: AppColors.gray800,
                          height: 22 / 14,
                        ),
                      ),
                    ],
                    if (hotel.bookingHint.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 18),
                      Text(
                        'BOOK ON',
                        style: AppTypography.micro.copyWith(
                          color: AppColors.gray500,
                          fontSize: 11,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hotel.bookingHint,
                        style: AppTypography.bodyL.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.micro.copyWith(
              color: AppColors.gray500,
              fontSize: 10,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.h3.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.gray200),
        ),
        clipBehavior: Clip.antiAlias,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 16 / 11,
              child: AppShimmer(
                child: ShimmerBox(height: double.infinity, radius: 0),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: AppShimmer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ShimmerBox(height: 12),
                    SizedBox(height: 6),
                    ShimmerBox(width: 90, height: 10),
                    SizedBox(height: 10),
                    ShimmerBox(width: 70),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
