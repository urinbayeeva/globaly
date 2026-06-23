import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_badge.dart';
import '../../../../core/widgets/pill.dart';
import '../../domain/entities/document_template.dart';

class DocumentRow extends StatelessWidget {
  const DocumentRow({super.key, required this.doc, this.onTap});
  final DocumentTemplate doc;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: <Widget>[
              IconBadge(
                icon: doc.icon,
                background: AppColors.appBg,
                foreground: AppColors.gray700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(doc.title, style: AppTypography.title),
                    const SizedBox(height: 2),
                    Text(
                      doc.issuer,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              _StatusPill(status: doc.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final DocumentStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case DocumentStatus.required:
        return const Pill(label: 'Required');
      case DocumentStatus.recommended:
        return const Pill(label: 'Recommended', tone: PillTone.amber);
      case DocumentStatus.optional:
        return const Pill(label: 'Optional', tone: PillTone.gray);
    }
  }
}
