import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';

class ScanEmptyView extends StatelessWidget {
  const ScanEmptyView({
    super.key,
    required this.onCamera,
    required this.onGallery,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.brandWash,
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
            child: Column(
              children: <Widget>[
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.brand.withValues(alpha: 0.12),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: AppColors.brand,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scan a contract',
                  style: AppTypography.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Take 3-4 photos of the pages. Globaly reads the text and flags any risky clauses before you sign.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyM.copyWith(color: AppColors.gray700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Open camera',
            icon: Icons.camera_alt_outlined,
            onPressed: onCamera,
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Pick from gallery',
            icon: Icons.photo_library_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: onGallery,
          ),
        ],
      ),
    );
  }
}
