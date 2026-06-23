import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadii.xxl,
    this.background,
    this.gradient,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;
  final Color? background;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final BorderRadius br = BorderRadius.circular(radius);
    final Widget body = Container(
      decoration: BoxDecoration(
        color: gradient == null ? (background ?? AppColors.surface) : null,
        gradient: gradient,
        borderRadius: br,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A0D1424),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x080D1424),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );

    if (onTap == null) return body;

    return Material(
      color: Colors.transparent,
      borderRadius: br,
      child: InkWell(
        borderRadius: br,
        onTap: onTap,
        child: body,
      ),
    );
  }
}
