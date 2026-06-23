import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/prefs.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/pill.dart';
import '../../../../core/widgets/score_ring.dart';
import '../bloc/home_cubit.dart';

class HomeScoreCard extends StatelessWidget {
  const HomeScoreCard({
    super.key,
    required this.score,
    required this.purposeCode,
    required this.country,
    required this.hasScore,
    required this.isSat,
  });

  final double score;
  final String purposeCode;
  final String country;
  final bool hasScore;

  final bool isSat;

  @override
  Widget build(BuildContext context) {
    if (purposeCode == 'study' && !hasScore) return const _EnterScoreCard();
    return _ReadinessCard(
      score: score > 0 ? score : 0.78,
      purposeCode: purposeCode,
      country: country,
      isSat: isSat,
    );
  }
}

class _EnterScoreCard extends StatefulWidget {
  const _EnterScoreCard();

  @override
  State<_EnterScoreCard> createState() => _EnterScoreCardState();
}

class _EnterScoreCardState extends State<_EnterScoreCard> {
  bool _isSat = false;
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String raw = _controller.text.trim();
    final double? v = double.tryParse(raw.replaceAll(',', '.'));
    if (v == null) {
      setState(() => _error = T.t('score.errorNumber'));
      return;
    }
    if (_isSat) {
      if (v < 400 || v > 1600) {
        setState(() => _error = T.t('score.errorSatRange'));
        return;
      }
    } else {
      if (v < 0 || v > 9) {
        setState(() => _error = T.t('score.errorIeltsRange'));
        return;
      }
    }
    final Prefs prefs = context.read<HomeCubit>().prefs;
    await prefs.setDouble(Prefs.kLanguageScore, v);
    if (!mounted) return;

    context.read<HomeCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
                  Icons.assignment_outlined,
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
                      T.of(context, 'score.enterTitle'),
                      style: AppTypography.h3.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      T.of(context, 'score.enterSubtitle'),
                      style: AppTypography.bodyM
                          .copyWith(color: AppColors.gray700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _TypeToggle(
                label: 'IELTS',
                selected: !_isSat,
                onTap: () => setState(() {
                  _isSat = false;
                  _error = null;
                  _controller.clear();
                }),
              ),
              const SizedBox(width: 6),
              _TypeToggle(
                label: 'SAT',
                selected: _isSat,
                onTap: () => setState(() {
                  _isSat = true;
                  _error = null;
                  _controller.clear();
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.numberWithOptions(decimal: !_isSat),
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              hintText: _isSat
                  ? T.of(context, 'score.placeholderSat')
                  : T.of(context, 'score.placeholderIelts'),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gray300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gray300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.brand,
                  width: 1.4,
                ),
              ),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                T.of(context, 'common.save'),
                style: AppTypography.bodyL.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand100 : AppColors.gray100,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.gray200,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyM.copyWith(
            color: selected ? AppColors.brand700 : AppColors.gray700,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({
    required this.score,
    required this.purposeCode,
    required this.country,
    required this.isSat,
  });

  final double score;
  final String purposeCode;
  final String country;
  final bool isSat;

  int get _pct => (score * 100).round();

  PillTone get _tone {
    if (_pct >= 70) return PillTone.green;
    if (_pct >= 40) return PillTone.amber;
    return PillTone.red;
  }

  String _bandLabel() {
    if (_pct >= 70) return T.t('score.bandHigh');
    if (_pct >= 40) return T.t('score.bandMedium');
    return T.t('score.bandLow');
  }

  _Copy _copy() {
    final String where = country.isEmpty ? T.t('nba.fallbackPlace') : country;
    final String test = isSat ? 'SAT' : 'IELTS';
    final String readiness =
        T.t('score.readinessTitle').replaceAll('{0}', '$_pct');
    switch (purposeCode) {
      case 'work':
        return _Copy(
          headline: readiness,
          helper: T.t('score.helper.work').replaceAll('{0}', where),
          cta: T.t('score.cta.viewJobs'),
          route: null,
        );
      case 'tourism':
        return _Copy(
          headline: readiness,
          helper: T.t('score.helper.tourism').replaceAll('{0}', where),
          cta: T.t('score.cta.explore').replaceAll('{0}', where),
          route: AppRoutes.explorePath(country),
        );
      case 'business':
        return _Copy(
          headline: readiness,
          helper: T.t('score.helper.business').replaceAll('{0}', where),
          cta: T.t('score.cta.openMap'),
          route: AppRoutes.opportunityMapPath(country),
        );
      case 'family':
        return _Copy(
          headline: T.t('score.family.headline'),
          helper: T.t('score.helper.family'),
          cta: T.t('score.cta.openChat'),
          route: AppRoutes.chat,
        );
      case 'study':
      default:
        return _Copy(
          headline: readiness,
          helper: isSat ? T.t('score.helper.sat') : T.t('score.helper.ielts'),
          cta: T.t('score.cta.breakdown').replaceAll('{0}', test),
          route: AppRoutes.score,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final _Copy c = _copy();
    return AppCard(
      onTap: c.route == null ? null : () => context.push(c.route!),
      child: Row(
        children: <Widget>[
          ScoreRing(value: score, size: 108, label: 'Score'),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Pill(label: _bandLabel(), tone: _tone),
                const SizedBox(height: 8),
                Text(
                  c.headline,
                  style: AppTypography.h3.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  c.helper,
                  style: AppTypography.bodyM.copyWith(color: AppColors.gray700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        c.cta,
                        style: AppTypography.bodyM.copyWith(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.brand,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Copy {
  const _Copy({
    required this.headline,
    required this.helper,
    required this.cta,
    required this.route,
  });
  final String headline;
  final String helper;
  final String cta;
  final String? route;
}
