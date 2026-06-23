import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/score_ring.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../universities/domain/entities/university.dart';
import '../../../universities/presentation/widgets/university_card.dart';
import '../bloc/score_cubit.dart';
import '../widgets/factor_breakdown_card.dart';
import '../widgets/slider_card.dart';

class ScorePage extends StatelessWidget {
  const ScorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScoreCubit>(
      create: (_) => sl<ScoreCubit>(),
      child: const _ScoreView(),
    );
  }
}

class _ScoreView extends StatelessWidget {
  const _ScoreView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBg,
      body: SafeArea(
        child: BlocBuilder<ScoreCubit, ScoreState>(
          builder: (BuildContext c, ScoreState s) {
            final ScoreCubit cubit = c.read<ScoreCubit>();
            return ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: <Widget>[
                _Header(onBack: () => context.pop()),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Center(
                    child: ScoreRing(value: s.score.toDouble(), size: 180),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 14, 28, 0),
                  child: Text(
                    "Your chance of approval for a German student visa, based on the data you've provided.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.family,
                      fontSize: 13,
                      color: AppColors.gray700,
                      height: 20 / 13,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _AiExplanation(ielts: s.ielts, score: s.score),
                ),
                const SizedBox(height: 16),
                const SectionLabel(
                  'Adjust factors',
                  padding: SectionLabel.standardPadding,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: <Widget>[
                      SliderCard(
                        label: 'IELTS score',
                        valueText: s.ielts.toStringAsFixed(1),
                        value: s.ielts,
                        min: 4,
                        max: 9,
                        divisions: 10,
                        onChanged: cubit.setIelts,
                      ),
                      const SizedBox(height: 10),
                      SliderCard(
                        label: 'Monthly budget',
                        valueText: '\$${s.budget}',
                        value: s.budget.toDouble(),
                        min: 600,
                        max: 2500,
                        divisions: 38,
                        onChanged: (double v) => cubit.setBudget(v.round()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const SectionLabel(
                  'Breakdown',
                  padding: SectionLabel.standardPadding,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FactorBreakdownCard(
                    rows: <FactorRow>[
                      FactorRow(
                        label: 'Language (IELTS)',
                        value: s.ielts.toStringAsFixed(1),
                        strong: s.ielts >= 6.5,
                      ),
                      FactorRow(
                        label: 'Budget',
                        value: '\$${s.budget}/mo',
                        strong: s.budget >= 1500,
                      ),
                      FactorRow(
                        label: 'Experience',
                        value: '${s.experienceYears} years',
                        strong: s.experienceYears >= 2,
                      ),
                      FactorRow(
                        label: 'Education',
                        value: s.education.label,
                        strong: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SectionLabel(
                  s.destinationCountryName.isEmpty
                      ? 'Universities'
                      : 'Universities in ${s.destinationCountryName}',
                  padding: SectionLabel.standardPadding,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _UniversitiesSection(state: s),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x0A0D1424),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Success Score',
            style: AppTypography.h2.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AiExplanation extends StatelessWidget {
  const _AiExplanation({required this.ielts, required this.score});
  final double ielts;
  final int score;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.brand,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'AI Explanation',
                style: AppTypography.bodyM.copyWith(
                  color: AppColors.brand700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: AppTypography.bodyL
                  .copyWith(color: AppColors.gray800, height: 22 / 14),
              children: <InlineSpan>[
                const TextSpan(
                  text:
                      'Your education and work experience are strong. Your IELTS score is just below what most German universities ask for. ',
                ),
                const TextSpan(
                  text: 'Raise it to 6.5',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' and your chances could reach '),
                TextSpan(
                  text: '${(score + 7).clamp(0, 100)}%',
                  style: const TextStyle(
                    color: AppColors.success700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UniversitiesSection extends StatelessWidget {
  const _UniversitiesSection({required this.state});
  final ScoreState state;

  @override
  Widget build(BuildContext context) {
    if (state.loadingUniversities) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }
    if (state.universities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.school_outlined,
              color: AppColors.gray400,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                state.universitiesError ?? 'No universities to show',
                style: AppTypography.bodyM.copyWith(color: AppColors.gray700),
              ),
            ),
          ],
        ),
      );
    }
    final List<University> visible = state.visibleUniversities;
    return Column(
      children: <Widget>[
        for (final University u in visible) UniversityCard(university: u),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Showing ${visible.length} of ${state.universities.length}',
            style: AppTypography.caption.copyWith(color: AppColors.gray500),
          ),
        ),
        if (state.hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 6),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.read<ScoreCubit>().loadMoreUniversities(),
                icon: const Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.brand,
                ),
                label: Text(
                  'Show ${state.remainingCount > ScoreState.pageSize ? ScoreState.pageSize : state.remainingCount} more',
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.brand200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
