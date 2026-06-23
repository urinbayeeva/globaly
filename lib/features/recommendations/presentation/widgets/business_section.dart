import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/sheet_grabber.dart';
import '../../domain/entities/business_opportunity.dart';
import '../bloc/business_cubit.dart';

class BusinessSection extends StatelessWidget {
  const BusinessSection({super.key, required this.country});
  final String country;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BusinessCubit>(
      create: (_) => sl<BusinessCubit>()..load(country),
      child: BlocBuilder<BusinessCubit, BusinessState>(
        builder: (BuildContext c, BusinessState s) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Business opportunities', style: AppTypography.h3),
              const SizedBox(height: 2),
              Text(
                country.isEmpty
                    ? 'Where to start a venture'
                    : 'Where to start a venture in $country',
                style: AppTypography.caption.copyWith(color: AppColors.gray500),
              ),
              const SizedBox(height: 12),
              _MapCard(state: s),
              const SizedBox(height: 12),
              _OpportunityList(state: s, cubit: c.read<BusinessCubit>()),
            ],
          );
        },
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.state});
  final BusinessState state;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.gray200),
        ),
        child: state.loading
            ? const AppShimmer(
                child: ColoredBox(color: Colors.white),
              )
            : (state.items.isEmpty
                ? _MapPlaceholder(message: state.error ?? 'No cities to plot')
                : _Map(state: state)),
      ),
    );
  }
}

class _Map extends StatelessWidget {
  const _Map({required this.state});
  final BusinessState state;

  @override
  Widget build(BuildContext context) {
    final List<LatLng> points = <LatLng>[
      for (final BusinessOpportunity o in state.items) LatLng(o.lat, o.lng),
    ];
    final LatLngBounds bounds = _boundsOf(points);
    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(40),
        ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.globaly.app',
          maxZoom: 19,
        ),
        MarkerLayer(
          markers: <Marker>[
            for (int i = 0; i < state.items.length; i++)
              Marker(
                point: LatLng(state.items[i].lat, state.items[i].lng),
                width: 44,
                height: 44,
                alignment: Alignment.topCenter,
                child: _Pin(
                  selected: state.selectedIndex == i,
                  demandLevel: state.items[i].demandLevel,
                  onTap: () {
                    context.read<BusinessCubit>().select(i);
                    _showSheet(context, state.items[i]);
                  },
                ),
              ),
          ],
        ),
        const RichAttributionWidget(
          attributions: <SourceAttribution>[
            TextSourceAttribution('© OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }

  LatLngBounds _boundsOf(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(const LatLng(0, 0), const LatLng(0, 0));
    }
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final LatLng p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    const double pad = 0.3;
    return LatLngBounds(
      LatLng(minLat - pad, minLng - pad),
      LatLng(maxLat + pad, maxLng + pad),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({
    required this.selected,
    required this.demandLevel,
    required this.onTap,
  });
  final bool selected;
  final String demandLevel;
  final VoidCallback onTap;

  Color get _color {
    switch (demandLevel) {
      case 'high':
        return AppColors.success;
      case 'low':
        return AppColors.gray500;
      case 'medium':
      default:
        return AppColors.brand;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _color;
    final double size = selected ? 32 : 26;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Icon(Icons.place_rounded, color: color, size: size + 8),
          Positioned(
            top: 4,
            child: Container(
              width: size - 12,
              height: size - 12,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.map_outlined,
              color: AppColors.gray400,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyM.copyWith(color: AppColors.gray700),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpportunityList extends StatelessWidget {
  const _OpportunityList({required this.state, required this.cubit});
  final BusinessState state;
  final BusinessCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return Column(
        children: List<Widget>.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 92,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: AppColors.gray200),
              ),
              child: const AppShimmer(
                child: Row(
                  children: <Widget>[
                    ShimmerBox(width: 40, height: 40, radius: 12),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          ShimmerBox(),
                          SizedBox(height: 8),
                          ShimmerBox(width: 180, height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (state.items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: <Widget>[
        for (int i = 0; i < state.items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OpportunityCard(
              opportunity: state.items[i],
              onTap: () {
                cubit.select(i);
                _showSheet(context, state.items[i]);
              },
            ),
          ),
      ],
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.opportunity, required this.onTap});
  final BusinessOpportunity opportunity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _demandBg(opportunity.demandLevel),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  color: _demandFg(opportunity.demandLevel),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            opportunity.city,
                            style: AppTypography.bodyL.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (opportunity.demandLevel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _demandBg(opportunity.demandLevel),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${opportunity.demandLevel} demand',
                              style: AppTypography.micro.copyWith(
                                color: _demandFg(opportunity.demandLevel),
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (opportunity.region.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        opportunity.region,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.gray500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (opportunity.summary.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        opportunity.summary,
                        style: AppTypography.bodyM.copyWith(
                          color: AppColors.gray700,
                          height: 18 / 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.gray400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _demandBg(String level) {
    switch (level) {
      case 'high':
        return AppColors.success100;
      case 'low':
        return AppColors.gray100;
      case 'medium':
      default:
        return AppColors.brand100;
    }
  }

  Color _demandFg(String level) {
    switch (level) {
      case 'high':
        return AppColors.success700;
      case 'low':
        return AppColors.gray700;
      case 'medium':
      default:
        return AppColors.brand700;
    }
  }
}

void _showSheet(BuildContext context, BusinessOpportunity o) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BusinessSheet(opportunity: o),
  );
}

class _BusinessSheet extends StatelessWidget {
  const _BusinessSheet({required this.opportunity});
  final BusinessOpportunity opportunity;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
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
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: <Widget>[
              const SheetGrabber(),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.brand100,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: const Icon(
                      Icons.place_rounded,
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
                          opportunity.city,
                          style: AppTypography.h2.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (opportunity.region.isNotEmpty)
                          Text(
                            opportunity.region,
                            style: AppTypography.caption
                                .copyWith(color: AppColors.gray500),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (opportunity.summary.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  opportunity.summary,
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.gray800,
                    height: 22 / 14,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const Text(
                'Business ideas',
                style: AppTypography.h3,
              ),
              const SizedBox(height: 10),
              for (final String idea in opportunity.ideas)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: AppColors.brand,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          idea,
                          style: AppTypography.bodyL.copyWith(
                            color: AppColors.gray800,
                            height: 22 / 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.gray400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI-generated suggestions — validate locally before investing.',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.gray500),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
