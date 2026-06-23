import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _baseColor,
      highlightColor: _highlightColor,
      period: const Duration(milliseconds: 1300),
      child: child,
    );
  }

  static const Color _baseColor = Color(0xFFDFE2E8);
  static const Color _highlightColor = Color(0xFFF6F7F9);
  static Color get baseColor => _baseColor;
}

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
  });

  static Widget shimmering({
    double? width,
    double height = 14,
    double radius = 8,
  }) {
    return AppShimmer(
      child: ShimmerBox(width: width, height: height, radius: radius),
    );
  }

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppShimmer.baseColor,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  const ShimmerCircle({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({
    super.key,
    this.height = 96,
    this.width,
    this.radius = 16,
    this.padding = const EdgeInsets.all(14),
    this.lines = 2,
  });

  final double height;
  final double? width;
  final double radius;
  final EdgeInsets padding;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: padding,
      child: AppShimmer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int i = 0; i < lines; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 8),
              ShimmerBox(
                width: i.isEven ? double.infinity : 160,
                height: i == 0 ? 14 : 10,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
