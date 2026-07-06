import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_colors.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brand100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap ?? () => context.pop(),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            PhosphorIconsRegular.caretLeft,
            color: AppColors.brand,
            size: 18,
          ),
        ),
      ),
    );
  }
}
