import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/sheet_grabber.dart';
import '../../domain/entities/document_template.dart';

class DocumentDetailSheet extends StatelessWidget {
  const DocumentDetailSheet({super.key, required this.doc});
  final DocumentTemplate doc;

  static Future<void> show(BuildContext context, DocumentTemplate doc) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DocumentDetailSheet(doc: doc),
    );
  }

  String get _statusLabel {
    switch (doc.status) {
      case DocumentStatus.required:
        return 'Required';
      case DocumentStatus.recommended:
        return 'Recommended';
      case DocumentStatus.optional:
        return 'Optional';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ScrollController c) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadii.sheetTop)),
        ),
        child: ListView(
          controller: c,
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
          children: <Widget>[
            const SheetGrabber(),
            const SizedBox(height: 14),
            _Header(statusLabel: _statusLabel, title: doc.title),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _IconBlock(doc: doc),
            ),
            if (doc.description.isNotEmpty) ...<Widget>[
              const SizedBox(height: 18),
              _AboutBlock(text: doc.description),
            ],
            if (doc.notes.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              _NotesBlock(notes: doc.notes),
            ],
            const SizedBox(height: 16),
            _MetaRow(doc: doc),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppButton(
                label: 'Got it',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.statusLabel, required this.title});
  final String statusLabel;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  statusLabel.toUpperCase(),
                  style: AppTypography.micro
                      .copyWith(color: AppColors.gray500, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTypography.h2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.appBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.gray700,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBlock extends StatelessWidget {
  const _IconBlock({required this.doc});
  final DocumentTemplate doc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.appBg,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.brand100,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(doc.icon, color: AppColors.brand, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'ISSUED BY',
                  style: AppTypography.micro.copyWith(
                    color: AppColors.gray500,
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doc.issuer.isEmpty ? '—' : doc.issuer,
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutBlock extends StatelessWidget {
  const _AboutBlock({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.brand,
                size: 16,
              ),
              const SizedBox(width: 10),
              Text(
                'What this is',
                style: AppTypography.bodyM.copyWith(
                  color: AppColors.brand700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AppTypography.bodyL.copyWith(
              color: AppColors.gray800,
              height: 22 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesBlock extends StatelessWidget {
  const _NotesBlock({required this.notes});
  final List<String> notes;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'GOOD TO KNOW',
            style: AppTypography.micro.copyWith(
              color: AppColors.gray500,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          for (final String n in notes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 14,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      n,
                      style: AppTypography.bodyL.copyWith(
                        color: AppColors.gray800,
                        height: 22 / 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.doc});
  final DocumentTemplate doc;

  @override
  Widget build(BuildContext context) {
    final List<_Meta> items = <_Meta>[
      if (doc.validityYears != null)
        _Meta(
          icon: Icons.event_available_outlined,
          label: 'VALIDITY',
          value: '${doc.validityYears} yr',
        ),
      if (doc.extendable)
        const _Meta(
          icon: Icons.refresh_rounded,
          label: 'EXTENDABLE',
          value: 'Yes',
        ),
      if (doc.convertibleTo != null && doc.convertibleTo!.isNotEmpty)
        _Meta(
          icon: Icons.swap_horiz_rounded,
          label: 'CONVERTS TO',
          value: doc.convertibleTo!,
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _MetaTile(meta: items[i])),
          ],
        ],
      ),
    );
  }
}

class _Meta {
  const _Meta({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.meta});
  final _Meta meta;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(meta.icon, size: 14, color: AppColors.gray500),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  meta.label,
                  style: AppTypography.micro.copyWith(
                    color: AppColors.gray500,
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            meta.value,
            style: AppTypography.bodyL.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
