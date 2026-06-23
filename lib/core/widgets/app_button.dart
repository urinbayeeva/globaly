import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || loading;
    final ({Color bg, Color fg, Color? border}) p = switch (variant) {
      AppButtonVariant.primary => (
          bg: AppColors.brand,
          fg: Colors.white,
          border: null,
        ),
      AppButtonVariant.secondary => (
          bg: AppColors.brand100,
          fg: AppColors.brand700,
          border: null,
        ),
      AppButtonVariant.ghost => (
          bg: Colors.transparent,
          fg: AppColors.brand,
          border: AppColors.brand200,
        ),
    };

    final Widget content = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(p.fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.button.copyWith(color: p.fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null) ...<Widget>[
                const SizedBox(width: 8),
                Icon(icon, size: 20, color: p.fg),
              ],
            ],
          );

    final Widget btn = AnimatedOpacity(
      opacity: disabled ? 0.55 : 1,
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: p.bg,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: disabled ? null : onPressed,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: p.border == null
                  ? null
                  : Border.all(color: p.border!, width: 1.5),
            ),
            child: Center(child: content),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
