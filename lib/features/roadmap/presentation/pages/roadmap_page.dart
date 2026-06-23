import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/app_topbar.dart';
import '../bloc/roadmap_cubit.dart';
import '../widgets/roadmap_tile.dart';

class RoadmapPage extends StatelessWidget {
  const RoadmapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RoadmapCubit>.value(
      value: sl<RoadmapCubit>()..ensureLoaded(),
      child: const _RoadmapView(),
    );
  }
}

class _RoadmapView extends StatelessWidget {
  const _RoadmapView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.appBg,
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<RoadmapCubit, RoadmapState>(
          builder: (BuildContext c, RoadmapState s) {
            final int done = s.doneCount;
            final int total = s.steps.isEmpty ? 1 : s.steps.length;
            final String subtitle = <String>[
              if (s.country.isNotEmpty) s.country,
              if (s.purposeLabel.isNotEmpty) s.purposeLabel,
            ].join(' · ');
            return ListView(
              padding: const EdgeInsets.only(bottom: 130),
              children: <Widget>[
                AppTopbar(
                  title: T.of(context, 'roadmap.title'),
                  subtitle: subtitle.isEmpty
                      ? T.of(context, 'roadmap.subtitleEmpty')
                      : subtitle,
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        T.of(context, 'roadmap.progress'),
                        style: AppTypography.micro.copyWith(
                          color: AppColors.gray500,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$done/$total',
                        style: AppTypography.h3.copyWith(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppTypography.tabular,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: done / total,
                      minHeight: 6,
                      backgroundColor: AppColors.gray100,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.brand),
                    ),
                  ),
                ),
                if (s.loading && s.steps.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: AppShimmer(
                      child: Row(
                        children: <Widget>[
                          const ShimmerBox(
                            width: 12,
                            height: 12,
                            radius: 999,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              T.of(context, 'roadmap.tailoring'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.gray500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (s.loading && s.steps.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: _RoadmapSkeleton(),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: Column(
                      children: List<Widget>.generate(s.steps.length, (int i) {
                        return RoadmapTile(
                          step: s.steps[i],
                          index: i,
                          isLast: i == s.steps.length - 1,
                        );
                      }),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RoadmapSkeleton extends StatelessWidget {
  const _RoadmapSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: Column(
        children: <Widget>[
          _SkeletonRow(),
          _SkeletonRow(),
          _SkeletonRow(),
          _SkeletonRow(),
          _SkeletonRow(),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ShimmerBox(width: 28, height: 28, radius: 999),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ShimmerBox(width: 160, radius: 6),
                SizedBox(height: 8),
                ShimmerBox(width: double.infinity, height: 11, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
