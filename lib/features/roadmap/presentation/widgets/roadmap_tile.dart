import 'package:flutter/material.dart' hide StepState;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/roadmap_step.dart';

class RoadmapTile extends StatelessWidget {
  const RoadmapTile({
    super.key,
    required this.step,
    required this.index,
    required this.isLast,
  });

  final RoadmapStep step;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _IndicatorColumn(state: step.state, index: index, isLast: isLast),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (step.state == StepState.current)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'NEXT BEST ACTION',
                        style: AppTypography.micro.copyWith(
                          color: AppColors.brand700,
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  Container(
                    padding: step.state == StepState.current
                        ? const EdgeInsets.all(12)
                        : EdgeInsets.zero,
                    decoration: step.state == StepState.current
                        ? BoxDecoration(
                            color: AppColors.brand100,
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                          )
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          step.title,
                          style: AppTypography.bodyL.copyWith(
                            color: step.state == StepState.done
                                ? AppColors.gray400
                                : AppColors.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            decoration: step.state == StepState.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: AppColors.gray500,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                step.description,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.gray500,
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
        ],
      ),
    );
  }
}

class _IndicatorColumn extends StatelessWidget {
  const _IndicatorColumn({
    required this.state,
    required this.index,
    required this.isLast,
  });
  final StepState state;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ({Color bg, Color? border, Color fg}) circle = switch (state) {
      StepState.done => (bg: AppColors.success, border: null, fg: Colors.white),
      StepState.current => (
          bg: AppColors.brand,
          border: null,
          fg: Colors.white
        ),
      StepState.upcoming => (
          bg: Colors.white,
          border: AppColors.gray300,
          fg: AppColors.gray400
        ),
    };
    return SizedBox(
      width: 32,
      child: Column(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: circle.bg,
              shape: BoxShape.circle,
              border: circle.border == null
                  ? null
                  : Border.all(color: circle.border!, width: 2),
            ),
            child: Center(
              child: state == StepState.done
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    )
                  : Text(
                      '${index + 1}',
                      style: AppTypography.caption.copyWith(
                        color: circle.fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: state == StepState.done
                    ? AppColors.success
                    : AppColors.gray300,
              ),
            ),
        ],
      ),
    );
  }
}
