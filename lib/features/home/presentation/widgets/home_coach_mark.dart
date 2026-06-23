import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/storage/prefs.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class HomeCoachMark {
  HomeCoachMark({
    required this.greetingKey,
    required this.docsKey,
    required this.nbaKey,
    required this.sectionKey,
  });

  final GlobalKey greetingKey;
  final GlobalKey docsKey;
  final GlobalKey nbaKey;
  final GlobalKey sectionKey;

  Future<void> maybeShow(BuildContext context) async {
    final Prefs prefs = sl<Prefs>();
    if (prefs.getBool(Prefs.kTourDone) == true) return;

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!context.mounted) return;
    TutorialCoachMark(
      targets: _buildTargets(context),
      colorShadow: AppColors.ink,
      opacityShadow: 0.78,
      paddingFocus: 8,
      hideSkip: true,
      onFinish: _markDone,
      onSkip: () {
        _markDone();
        return true;
      },
    ).show(context: context);
  }

  void _markDone() {
    sl<Prefs>().setBool(Prefs.kTourDone, true);
  }

  List<TargetFocus> _buildTargets(BuildContext context) {
    return <TargetFocus>[
      _target(
        identify: 'greeting',
        keyTarget: greetingKey,
        title: T.of(context, 'tour.greeting.title'),
        body: T.of(context, 'tour.greeting.body'),
        align: ContentAlign.bottom,
        ctaKey: 'tour.next',
        context: context,
      ),
      _target(
        identify: 'docs',
        keyTarget: docsKey,
        title: T.of(context, 'tour.docs.title'),
        body: T.of(context, 'tour.docs.body'),
        align: ContentAlign.bottom,
        ctaKey: 'tour.next',
        context: context,
      ),
      _target(
        identify: 'nba',
        keyTarget: nbaKey,
        title: T.of(context, 'tour.nba.title'),
        body: T.of(context, 'tour.nba.body'),
        align: ContentAlign.top,
        ctaKey: 'tour.next',
        context: context,
      ),
      _target(
        identify: 'purpose',
        keyTarget: sectionKey,
        title: T.of(context, 'tour.purpose.title'),
        body: T.of(context, 'tour.purpose.body'),
        align: ContentAlign.top,
        ctaKey: 'tour.gotIt',
        context: context,
      ),
    ];
  }

  TargetFocus _target({
    required String identify,
    required GlobalKey keyTarget,
    required String title,
    required String body,
    required ContentAlign align,
    required String ctaKey,
    required BuildContext context,
  }) {
    return TargetFocus(
      identify: identify,
      keyTarget: keyTarget,
      shape: ShapeLightFocus.Circle,
      radius: 44,
      enableOverlayTab: true,
      contents: <TargetContent>[
        TargetContent(
          align: align,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          builder: (BuildContext c, TutorialCoachMarkController ctrl) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTypography.h3.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: AppTypography.bodyL.copyWith(
                      color: AppColors.gray800,
                      height: 22 / 14,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: ctrl.next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(T.of(context, ctaKey)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
