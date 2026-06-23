import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

class PagesThumbnails extends StatelessWidget {
  const PagesThumbnails({
    super.key,
    required this.paths,
    required this.onAdd,
    required this.onReset,
  });

  final List<String> paths;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: <Widget>[
          ...paths.map((String p) => _Thumb(path: p)),
          _AddTile(onTap: onAdd),
          const SizedBox(width: 12),
          _ResetTile(onTap: onReset),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path});
  final String path;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Image.file(
          File(path),
          width: 84,
          height: 110,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.brand100,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: AppColors.brand.withValues(alpha: 0.5),
            width: 1.4,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.add_a_photo_outlined, color: AppColors.brand),
            const SizedBox(height: 6),
            Text(
              'Add page',
              style: AppTypography.caption.copyWith(color: AppColors.brand),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetTile extends StatelessWidget {
  const _ResetTile({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.refresh_rounded, color: AppColors.gray500),
            SizedBox(height: 6),
            Text('Reset'),
          ],
        ),
      ),
    );
  }
}
