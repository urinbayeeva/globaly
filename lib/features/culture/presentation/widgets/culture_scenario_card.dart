import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/culture_briefing.dart';

class CultureScenarioCard extends StatelessWidget {
  const CultureScenarioCard({
    super.key,
    required this.index,
    required this.scenario,
    required this.selected,
    required this.onSelect,
  });

  final int index;
  final CultureScenario scenario;
  final int? selected;
  final ValueChanged<int> onSelect;

  bool get _answered => selected != null;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            T.of(context, 'culture.scenario').replaceAll('{0}', '${index + 1}'),
            style: AppTypography.micro.copyWith(
              color: AppColors.gray500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            scenario.situation,
            style: AppTypography.bodyL.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              height: 21 / 15,
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < scenario.options.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == scenario.options.length - 1 ? 0 : 8,
              ),
              child: _OptionTile(
                text: scenario.options[i],
                state: _stateFor(i),
                onTap: _answered ? null : () => onSelect(i),
              ),
            ),
          if (_answered) ...<Widget>[
            const SizedBox(height: 14),
            _Explanation(
              correct: scenario.isCorrect(selected!),
              text: scenario.explanation,
            ),
          ],
        ],
      ),
    );
  }

  _OptionState _stateFor(int i) {
    if (!_answered) return _OptionState.idle;
    if (i == scenario.correctIndex) return _OptionState.correct;
    if (i == selected) return _OptionState.wrong;
    return _OptionState.muted;
  }
}

enum _OptionState { idle, correct, wrong, muted }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ({Color bg, Color border, Color fg, IconData? icon, Color iconColor})
        p = switch (state) {
      _OptionState.idle => (
          bg: Colors.white,
          border: AppColors.gray200,
          fg: AppColors.gray800,
          icon: null,
          iconColor: AppColors.gray400,
        ),
      _OptionState.correct => (
          bg: AppColors.success100,
          border: AppColors.success,
          fg: AppColors.success700,
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.success,
        ),
      _OptionState.wrong => (
          bg: AppColors.alert100,
          border: AppColors.alert,
          fg: AppColors.alert700,
          icon: Icons.cancel_rounded,
          iconColor: AppColors.alert,
        ),
      _OptionState.muted => (
          bg: AppColors.appBg,
          border: AppColors.gray200,
          fg: AppColors.gray500,
          icon: null,
          iconColor: AppColors.gray400,
        ),
    };

    return Material(
      color: p.bg,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: p.border, width: 1.4),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  text,
                  style: AppTypography.bodyL.copyWith(
                    color: p.fg,
                    height: 20 / 14,
                  ),
                ),
              ),
              if (p.icon != null) ...<Widget>[
                const SizedBox(width: 10),
                Icon(p.icon, color: p.iconColor, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation({required this.correct, required this.text});

  final bool correct;
  final String text;

  @override
  Widget build(BuildContext context) {
    final Color tone = correct ? AppColors.success : AppColors.warning;
    final Color bg = correct ? AppColors.success100 : AppColors.warning100;
    final String label = T.of(
      context,
      correct ? 'culture.correct' : 'culture.incorrect',
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                correct
                    ? Icons.check_circle_rounded
                    : Icons.info_rounded,
                color: tone,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: AppTypography.micro.copyWith(
                  color: tone,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: AppTypography.bodyM.copyWith(
              color: AppColors.gray800,
              height: 19 / 13,
            ),
          ),
        ],
      ),
    );
  }
}
