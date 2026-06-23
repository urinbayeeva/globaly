import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.value,
    this.size = 132,
    this.label,
  });

  final double value;
  final double size;
  final String? label;

  double get _pct {
    final double v = value > 1.0 ? value : value * 100;
    return v.clamp(0, 100);
  }

  ({Color fg, Color bg}) get _palette {
    final double v = _pct;
    if (v >= 70) return (fg: AppColors.success, bg: AppColors.success100);
    if (v >= 40) return (fg: AppColors.warning, bg: AppColors.warning100);
    return (fg: AppColors.brand, bg: AppColors.brand100);
  }

  @override
  Widget build(BuildContext context) {
    final ({Color fg, Color bg}) p = _palette;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(progress: _pct / 100, fg: p.fg, bg: p.bg),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        '${_pct.round()}',
                        style: TextStyle(
                          fontFamily: AppTypography.family,
                          fontSize: size * 0.28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          letterSpacing: -0.5,
                          height: 1,
                          fontFeatures: AppTypography.tabular,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: size * 0.04),
                        child: Text(
                          '%',
                          style: TextStyle(
                            fontFamily: AppTypography.family,
                            fontSize: size * 0.16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray500,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (label != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      label!.toUpperCase(),
                      style: AppTypography.micro.copyWith(
                        color: AppColors.gray500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.fg, required this.bg});
  final double progress;
  final Color fg;
  final Color bg;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;
    final Paint bgPaint = Paint()..color = bg;
    final Paint fgPaint = Paint()..color = fg;

    canvas.drawCircle(center, radius, bgPaint);

    final Path arc = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
      )
      ..close();
    canvas.drawPath(arc, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.fg != fg || old.bg != bg;
}
