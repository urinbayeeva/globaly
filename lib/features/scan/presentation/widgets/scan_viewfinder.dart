import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ScanViewfinder extends StatelessWidget {
  const ScanViewfinder({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'EMPLOYMENT CONTRACT',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...List<Widget>.generate(20, (int i) {
                        final bool highlight = i == 10 || i == 14;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.5),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.6 + (i % 5) * 0.08,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: highlight
                                    ? AppColors.alert100
                                    : AppColors.gray100,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            ..._cornerPositions().map(
              (Alignment a) => Align(
                alignment: a,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _Corner(alignment: a),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Alignment> _cornerPositions() => const <Alignment>[
        Alignment.topLeft,
        Alignment.topRight,
        Alignment.bottomLeft,
        Alignment.bottomRight,
      ];
}

class _Corner extends StatelessWidget {
  const _Corner({required this.alignment});
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final bool top = alignment.y < 0;
    final bool left = alignment.x < 0;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? const BorderSide(color: AppColors.brand, width: 3)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: AppColors.brand, width: 3)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: AppColors.brand, width: 3)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: AppColors.brand, width: 3)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? const Radius.circular(8) : Radius.zero,
          topRight: top && !left ? const Radius.circular(8) : Radius.zero,
          bottomLeft: !top && left ? const Radius.circular(8) : Radius.zero,
          bottomRight: !top && !left ? const Radius.circular(8) : Radius.zero,
        ),
      ),
    );
  }
}
