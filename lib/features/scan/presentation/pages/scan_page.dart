import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_topbar.dart';
import '../../../../core/widgets/section_label.dart';
import '../../domain/entities/scan_analysis.dart';
import '../bloc/scan_cubit.dart';
import '../widgets/danger_banner.dart';
import '../widgets/detected_risk_card.dart';
import '../widgets/scan_progress.dart';
import '../widgets/scan_viewfinder.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScanCubit>(
      create: (_) => sl<ScanCubit>(),
      child: const _ScanView(),
    );
  }
}

class _ScanView extends StatelessWidget {
  const _ScanView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.appBg,
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<ScanCubit, ScanState>(
          builder: (BuildContext c, ScanState s) {
            final ScanCubit cubit = c.read<ScanCubit>();
            final bool analysing = s.status == ScanStatus.analyzing ||
                s.status == ScanStatus.scanning;
            return ListView(
              padding: const EdgeInsets.only(bottom: 130),
              children: <Widget>[
                AppTopbar(
                  title: T.of(context, 'scan.title'),
                  subtitle: analysing
                      ? T.of(context, 'scan.analysing')
                      : T.of(context, 'scan.subtitle'),
                ),
                if (analysing && s.pages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: ScanProgress(
                      imagePath: s.pages.last,
                      phase: s.phase,
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: ScanViewfinder(),
                  ),
                const SizedBox(height: 16),
                if (!analysing && s.analysis == null)
                  _CaptureButtons(cubit: cubit)
                else if (s.analysis != null) ...<Widget>[
                  _ResultView(analysis: s.analysis!),
                  const SizedBox(height: 16),
                  _SecondaryActions(cubit: cubit),
                ],
                if (s.message != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Text(
                      s.message!,
                      style: AppTypography.bodyM
                          .copyWith(color: AppColors.alert700),
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

class _CaptureButtons extends StatelessWidget {
  const _CaptureButtons({required this.cubit});
  final ScanCubit cubit;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: <Widget>[
          Expanded(
            child: AppButton(
              label: T.of(context, 'scan.openCamera'),
              icon: Icons.camera_alt_outlined,
              onPressed: cubit.capturePage,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton(
              label: T.of(context, 'scan.gallery'),
              icon: Icons.photo_library_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: cubit.addFromGallery,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryActions extends StatelessWidget {
  const _SecondaryActions({required this.cubit});
  final ScanCubit cubit;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: <Widget>[
          Expanded(
            child: AppButton(
              label: T.of(context, 'scan.scanAnother'),
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: cubit.reset,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.analysis});
  final ScanAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    if (!analysis.isContract) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _WrongDocNotice(analysis: analysis),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (analysis.risks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DangerBanner(count: analysis.risks.length),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SafeContractBanner(),
          ),
        if (analysis.summary.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SummaryCard(text: analysis.summary),
          ),
        ],
        if (analysis.risks.isNotEmpty) ...<Widget>[
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: SectionLabel(T.of(context, 'scan.riskyClauses')),
          ),
          ...analysis.risks.map(
            (DetectedRisk risk) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: DetectedRiskCard(risk: risk),
            ),
          ),
        ],
        if (analysis.safePoints.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: SectionLabel(T.of(context, 'scan.safePoints')),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SafePointsCard(points: analysis.safePoints),
          ),
        ],
      ],
    );
  }
}

class _WrongDocNotice extends StatelessWidget {
  const _WrongDocNotice({required this.analysis});
  final ScanAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning100,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.warning200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.warning,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  T
                      .of(context, 'scan.wrongDocTitle')
                      .replaceAll('{0}', analysis.type.label),
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.warning700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            T.of(context, 'scan.wrongDocBody'),
            style: AppTypography.bodyL.copyWith(
              color: AppColors.warning700,
              height: 22 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SafeContractBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success100,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: const Color(0xFFB5E5C7)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.verified_rounded,
            color: AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              T.of(context, 'scan.safeNotice'),
              style: AppTypography.bodyM.copyWith(
                color: AppColors.success700,
                height: 18 / 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.text});
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.brand,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyL.copyWith(
                color: AppColors.gray800,
                height: 22 / 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafePointsCard extends StatelessWidget {
  const _SafePointsCard({required this.points});
  final List<String> points;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final String p in points)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p,
                      style: AppTypography.bodyL.copyWith(
                        color: AppColors.gray800,
                        height: 22 / 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
