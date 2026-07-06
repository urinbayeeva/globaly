import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/storage/prefs.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/app_topbar.dart';
import '../../../../core/widgets/async_state_view.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../profile_setup/data/datasources/countries_db.dart';
import '../../../profile_setup/domain/entities/country.dart';
import '../../domain/culture_briefing.dart';
import '../bloc/culture_cubit.dart';
import '../widgets/culture_scenario_card.dart';

class CultureCompassPage extends StatelessWidget {
  const CultureCompassPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? code = sl<Prefs>().getString(Prefs.kDestinationCountry);
    final Country? country =
        code == null ? null : sl<CountriesDb>().byCode(code);

    return BlocProvider<CultureCubit>(
      create: (_) => sl<CultureCubit>()
        ..load(
          country: country?.name ?? '',
          flag: country?.flagEmoji ?? '🌍',
        ),
      child: _CultureView(country: country),
    );
  }
}

class _CultureView extends StatelessWidget {
  const _CultureView({required this.country});

  final Country? country;

  void _retry(BuildContext context) => context.read<CultureCubit>().load(
        country: country?.name ?? '',
        flag: country?.flagEmoji ?? '🌍',
      );

  @override
  Widget build(BuildContext context) {
    final String name = country?.name ?? '';
    return Scaffold(
      backgroundColor: AppColors.appBg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopbar(
              title: T.of(context, 'culture.title'),
              subtitle: name.isEmpty ? null : name,
              leading: const AppBackButton(),
            ),
            Expanded(
              child: BlocBuilder<CultureCubit, CultureState>(
                builder: (BuildContext context, CultureState state) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: <Widget>[
                      _Banner(country: name),
                      const SizedBox(height: 18),
                      AsyncStateView<void>(
                        isLoading: state.status == CultureStatus.loading,
                        error: state.status == CultureStatus.error
                            ? state.error
                            : null,
                        isEmpty: state.briefing?.isEmpty ?? true,
                        onRetry: () => _retry(context),
                        emptyLabel: T.of(context, 'culture.empty'),
                        loadingPlaceholder: (_) => const _Skeleton(),
                        builder: (BuildContext c) => _Content(
                          briefing: state.briefing!,
                          state: state,
                          cubit: c.read<CultureCubit>(),
                        ),
                      ),
                    ],
                  );
                },
              ),
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
        ? T.of(context, 'culture.bannerSubtitleGeneric')
        : T.of(context, 'culture.bannerSubtitle').replaceAll('{0}', country);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.brandSolid,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.explore_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  T.of(context, 'culture.bannerTitle'),
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

class _Content extends StatelessWidget {
  const _Content({
    required this.briefing,
    required this.state,
    required this.cubit,
  });

  final CultureBriefing briefing;
  final CultureState state;
  final CultureCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (briefing.headline.isNotEmpty) ...<Widget>[
          _Headline(text: briefing.headline),
          const SizedBox(height: 18),
        ],
        if (briefing.facts.isNotEmpty) ...<Widget>[
          SectionLabel(T.of(context, 'culture.factsLabel')),
          const SizedBox(height: 10),
          _FactsGrid(facts: briefing.facts),
          const SizedBox(height: 22),
        ],
        if (briefing.sections.isNotEmpty) ...<Widget>[
          SectionLabel(T.of(context, 'culture.knowLabel')),
          const SizedBox(height: 10),
          for (final CultureSection section in briefing.sections) ...<Widget>[
            _SectionCard(section: section),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 10),
        ],
        if (briefing.scenarios.isNotEmpty)
          _Quiz(briefing: briefing, state: state, cubit: cubit),
        const SizedBox(height: 18),
        Center(
          child: Text(
            T.of(context, 'culture.disclaimer'),
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.gray400),
          ),
        ),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brand100,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.format_quote_rounded,
            color: AppColors.brand,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyL.copyWith(
                color: AppColors.brand700,
                fontWeight: FontWeight.w600,
                height: 21 / 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactsGrid extends StatelessWidget {
  const _FactsGrid({required this.facts});

  final List<CultureFact> facts;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      children:
          facts.map((CultureFact f) => _FactChip(fact: f)).toList(),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.fact});

  final CultureFact fact;

  @override
  Widget build(BuildContext context) {
    final ({IconData icon, Color tint, Color fg}) v = _visualFor(fact.kind);
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: v.tint,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(v.icon, color: v.fg, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  T.of(context, _labelKey(fact.kind)).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.micro.copyWith(
                    color: AppColors.gray500,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fact.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyM.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                    height: 17 / 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _labelKey(CultureFactKind kind) {
    switch (kind) {
      case CultureFactKind.greeting:
        return 'culture.fact.greeting';
      case CultureFactKind.tipping:
        return 'culture.fact.tipping';
      case CultureFactKind.punctuality:
        return 'culture.fact.punctuality';
      case CultureFactKind.dress:
        return 'culture.fact.dress';
      case CultureFactKind.other:
        return 'culture.fact.other';
    }
  }

  ({IconData icon, Color tint, Color fg}) _visualFor(CultureFactKind kind) {
    switch (kind) {
      case CultureFactKind.greeting:
        return (
          icon: Icons.waving_hand_rounded,
          tint: AppColors.success100,
          fg: AppColors.success,
        );
      case CultureFactKind.tipping:
        return (
          icon: Icons.payments_rounded,
          tint: AppColors.warning100,
          fg: AppColors.warning,
        );
      case CultureFactKind.punctuality:
        return (
          icon: Icons.schedule_rounded,
          tint: AppColors.info100,
          fg: AppColors.info,
        );
      case CultureFactKind.dress:
        return (
          icon: Icons.checkroom_rounded,
          tint: AppColors.brand100,
          fg: AppColors.brand,
        );
      case CultureFactKind.other:
        return (
          icon: Icons.public_rounded,
          tint: AppColors.gray100,
          fg: AppColors.gray500,
        );
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final CultureSection section;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            section.title,
            style: AppTypography.title,
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < section.tips.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == section.tips.length - 1 ? 0 : 10,
              ),
              child: _TipRow(tip: section.tips[i]),
            ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.tip});

  final CultureTip tip;

  @override
  Widget build(BuildContext context) {
    final Color tone = tip.isDo ? AppColors.success : AppColors.alert;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            tip.isDo ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: tone,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            tip.text,
            style: AppTypography.bodyL.copyWith(
              color: AppColors.gray800,
              height: 20 / 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _Quiz extends StatelessWidget {
  const _Quiz({
    required this.briefing,
    required this.state,
    required this.cubit,
  });

  final CultureBriefing briefing;
  final CultureState state;
  final CultureCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: SectionLabel(T.of(context, 'culture.quizLabel')),
            ),
            _ProgressPill(
              done: state.answeredScenarios,
              total: state.totalScenarios,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          T.of(context, 'culture.quizIntro'),
          style: AppTypography.bodyM.copyWith(color: AppColors.gray500),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < briefing.scenarios.length; i++) ...<Widget>[
          CultureScenarioCard(
            index: i,
            scenario: briefing.scenarios[i],
            selected: state.answers[i],
            onSelect: (int option) => cubit.selectAnswer(i, option),
          ),
          const SizedBox(height: 12),
        ],
        if (state.quizComplete) ...<Widget>[
          const SizedBox(height: 4),
          _ResultBanner(
            correct: state.correctScenarios,
            total: state.totalScenarios,
          ),
          const SizedBox(height: 12),
          AppButton(
            label: T.of(context, 'culture.retake'),
            icon: Icons.refresh_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: cubit.retakeQuiz,
          ),
        ],
      ],
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        '$done/$total',
        style: AppTypography.micro.copyWith(
          color: AppColors.gray700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.correct, required this.total});

  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) {
    final bool perfect = correct == total;
    final bool good = correct * 2 >= total;
    final Color tone = perfect
        ? AppColors.success
        : (good ? AppColors.warning : AppColors.alert);
    final Color bg = perfect
        ? AppColors.success100
        : (good ? AppColors.warning100 : AppColors.alert100);
    final String headline = T.of(
      context,
      perfect
          ? 'culture.result.great'
          : (good ? 'culture.result.good' : 'culture.result.low'),
    );
    final String score = T
        .of(context, 'culture.score')
        .replaceAll('{0}', '$correct')
        .replaceAll('{1}', '$total');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              perfect
                  ? Icons.emoji_events_rounded
                  : Icons.school_rounded,
              color: tone,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  headline,
                  style: AppTypography.title.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  score,
                  style:
                      AppTypography.bodyM.copyWith(color: AppColors.gray700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        ShimmerCard(height: 68),
        SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(child: ShimmerCard(height: 68)),
            SizedBox(width: 10),
            Expanded(child: ShimmerCard(height: 68)),
          ],
        ),
        SizedBox(height: 14),
        ShimmerCard(height: 150),
        SizedBox(height: 12),
        ShimmerCard(height: 150),
      ],
    );
  }
}
