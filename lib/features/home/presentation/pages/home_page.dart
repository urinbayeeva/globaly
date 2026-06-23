import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../documents/presentation/bloc/required_docs_cubit.dart';
import '../../../recommendations/presentation/widgets/business_cta_banner.dart';
import '../../../recommendations/presentation/widgets/family_section.dart';
import '../../../recommendations/presentation/widgets/travel_section.dart';
import '../../../recommendations/presentation/widgets/visa_info_banner.dart';
import '../../../recommendations/presentation/widgets/work_section.dart';
import '../../domain/entities/home_snapshot.dart';
import '../bloc/home_cubit.dart';
import '../widgets/home_coach_mark.dart';
import '../widgets/home_docs_strip.dart';
import '../widgets/home_greeting_header.dart';
import '../widgets/home_score_card.dart';
import '../widgets/next_best_action_card.dart';
import '../widgets/smart_tools_grid.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<HomeCubit>(create: (_) => sl<HomeCubit>()..load()),
        BlocProvider<RequiredDocsCubit>.value(
          value: sl<RequiredDocsCubit>()..load(),
        ),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final GlobalKey _greetingKey = GlobalKey();
  final GlobalKey _docsKey = GlobalKey();
  final GlobalKey _nbaKey = GlobalKey();
  final GlobalKey _sectionKey = GlobalKey();

  bool _tourAttempted = false;

  late final HomeCoachMark _coach = HomeCoachMark(
    greetingKey: _greetingKey,
    docsKey: _docsKey,
    nbaKey: _nbaKey,
    sectionKey: _sectionKey,
  );

  void _maybeStartTour() {
    if (_tourAttempted) return;
    _tourAttempted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _coach.maybeShow(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFEECEE),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Container(
        color: const Color(0xFFFEECEE),
        child: SafeArea(
          bottom: false,
          child: Container(
            color: AppColors.appBg,
            child: BlocConsumer<HomeCubit, HomeState>(
              listener: (BuildContext c, HomeState s) {
                if (s.snapshot != null) _maybeStartTour();
              },
              builder: (BuildContext c, HomeState s) {
                if (s.snapshot == null) {
                  return const _HomeSkeleton();
                }
                final String purpose = s.snapshot!.purposeCode;
                final String country = s.snapshot!.destinationCountryName;
                return ListView(
                  padding: const EdgeInsets.only(bottom: 130),
                  children: <Widget>[
                    _CoachAnchor(
                      anchorKey: _greetingKey,
                      alignment: Alignment.topRight,
                      inset: const EdgeInsets.only(top: 18, right: 24),
                      child: HomeGreetingHeader(snapshot: s.snapshot!),
                    ),
                    if (purpose != 'family') ...<Widget>[
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: VisaInfoBanner(
                          country: country,
                          purposeCode: purpose,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _CoachAnchor(
                      anchorKey: _docsKey,
                      alignment: Alignment.topLeft,
                      inset: const EdgeInsets.only(top: 4, left: 28),
                      child: const HomeDocsStrip(),
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Text(
                        T.of(context, 'home.nba.label'),
                        style: AppTypography.h3,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _CoachAnchor(
                        anchorKey: _nbaKey,
                        alignment: Alignment.topLeft,
                        inset: const EdgeInsets.only(top: 22, left: 22),
                        child: NextBestActionCard(
                          stepLabel: s.snapshot!.nbaStepLabel,
                          title: s.snapshot!.nbaTitle,
                          timeEstimate: s.snapshot!.nbaTimeEstimate,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Text(
                        _sectionTitle(context, purpose),
                        style: AppTypography.h3,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _CoachAnchor(
                        anchorKey: _sectionKey,
                        alignment: Alignment.topCenter,
                        inset: const EdgeInsets.only(top: 24),
                        child: _PurposeSection(
                          purposeCode: purpose,
                          country: country,
                          snapshot: s.snapshot!,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Text(
                        T.of(context, 'home.smartTools'),
                        style: AppTypography.h3,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SmartToolsGrid(purposeCode: purpose),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _sectionTitle(BuildContext context, String purpose) {
    switch (purpose) {
      case 'work':
        return T.of(context, 'home.section.work');
      case 'tourism':
        return T.of(context, 'home.section.tourism');
      case 'business':
        return T.of(context, 'home.section.business');
      case 'family':
        return T.of(context, 'home.section.family');
      case 'study':
      default:
        return T.of(context, 'home.section.readiness');
    }
  }
}

class _CoachAnchor extends StatelessWidget {
  const _CoachAnchor({
    required this.anchorKey,
    required this.alignment,
    required this.inset,
    required this.child,
  });
  final GlobalKey anchorKey;
  final Alignment alignment;
  final EdgeInsets inset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        child,
        Positioned(
          left: alignment.x <= 0 ? inset.left : null,
          right: alignment.x >= 0 && alignment.x > 0 ? inset.right : null,
          top: alignment.y <= 0 ? inset.top : null,
          bottom: alignment.y > 0 ? inset.bottom : null,
          child: IgnorePointer(
            child: SizedBox(
              key: anchorKey,
              width: 44,
              height: 44,
            ),
          ),
        ),
      ],
    );
  }
}

class _PurposeSection extends StatelessWidget {
  const _PurposeSection({
    required this.purposeCode,
    required this.country,
    required this.snapshot,
  });
  final String purposeCode;
  final String country;
  final HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    switch (purposeCode) {
      case 'work':
        return WorkSection(country: country);
      case 'tourism':
        return TravelSection(country: country);
      case 'business':
        return BusinessCtaBanner(country: country);
      case 'family':
        return FamilySection(country: country);
      case 'study':
      default:
        return HomeScoreCard(
          score: snapshot.scoreValue,
          purposeCode: purposeCode,
          country: country,
          hasScore: snapshot.hasLanguageScore,
          isSat: snapshot.languageScoreIsSat,
        );
    }
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: const BoxDecoration(gradient: AppColors.brandWash),
          child: const AppShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ShimmerBox(width: 120, height: 12),
                          SizedBox(height: 8),
                          ShimmerBox(width: 180, height: 22),
                        ],
                      ),
                    ),
                    ShimmerBox(width: 44, height: 44, radius: 14),
                  ],
                ),
                SizedBox(height: 18),
                ShimmerBox(height: 64, radius: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: AppShimmer(
            child: ShimmerBox(height: 110, radius: 16),
          ),
        ),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: AppShimmer(
            child: ShimmerBox(width: 180, height: 18),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => const AppShimmer(
              child: SizedBox(
                width: 160,
                child: ShimmerBox(height: 196, radius: 18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: AppShimmer(
            child: ShimmerBox(height: 128, radius: 16),
          ),
        ),
        const SizedBox(height: 22),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: AppShimmer(
            child: ShimmerBox(height: 200, radius: 16),
          ),
        ),
      ],
    );
  }
}
