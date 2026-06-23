import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile.value({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
    this.onTap,
  })  : toggle = false,
        on = false,
        onToggle = null;

  const SettingsTile.toggle({
    super.key,
    required this.icon,
    required this.label,
    required this.on,
    required this.onToggle,
    this.last = false,
  })  : toggle = true,
        value = '',
        onTap = null;

  final IconData icon;
  final String label;
  final String value;
  final bool last;
  final VoidCallback? onTap;
  final bool toggle;
  final bool on;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: toggle ? () => onToggle?.call(!on) : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: last
                  ? BorderSide.none
                  : const BorderSide(color: AppColors.gray100),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.appBg,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(icon, color: AppColors.gray700, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (toggle)
                _SmallToggle(value: on, onChanged: onToggle ?? (_) {})
              else ...<Widget>[
                Text(
                  value,
                  style: AppTypography.bodyM.copyWith(color: AppColors.gray500),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.gray400,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallToggle extends StatelessWidget {
  const _SmallToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? AppColors.brand : AppColors.gray300,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
