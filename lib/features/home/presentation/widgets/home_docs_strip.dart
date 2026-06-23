import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/pill.dart';
import '../../../documents/domain/entities/document_template.dart';
import '../../../documents/presentation/bloc/required_docs_cubit.dart';
import '../../../documents/presentation/widgets/document_detail_sheet.dart';

class HomeDocsStrip extends StatelessWidget {
  const HomeDocsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RequiredDocsCubit, RequiredDocsState>(
      builder: (BuildContext c, RequiredDocsState s) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: <Widget>[
                  Text(
                    T.of(context, 'docs.title'),
                    style: AppTypography.h3,
                  ),
                  const Spacer(),
                  Text(
                    T.of(context, 'common.seeAll'),
                    style: AppTypography.bodyM.copyWith(
                      color: AppColors.brand,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 196,
              child: s.status == DocsStatus.loading && s.docs.isEmpty
                  ? const _DocsStripShimmer()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: s.docs.length.clamp(0, 6),
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, int i) => _DocTile(
                        doc: s.docs[i],
                        onTap: () =>
                            DocumentDetailSheet.show(context, s.docs[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({required this.doc, required this.onTap});
  final DocumentTemplate doc;
  final VoidCallback onTap;

  PillTone get _tone {
    switch (doc.status) {
      case DocumentStatus.required:
        return PillTone.brand;
      case DocumentStatus.recommended:
        return PillTone.amber;
      case DocumentStatus.optional:
        return PillTone.gray;
    }
  }

  String _statusLabel(BuildContext context) {
    switch (doc.status) {
      case DocumentStatus.required:
        return T.of(context, 'common.required');
      case DocumentStatus.recommended:
        return T.of(context, 'common.recommended');
      case DocumentStatus.optional:
        return T.of(context, 'common.optional');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0A0D1424),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Preview(icon: doc.icon),
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: Text(
                doc.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyM.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 17 / 13,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Pill(label: _statusLabel(context), tone: _tone),
          ],
        ),
      ),
    );
  }
}

class _DocsStripShimmer extends StatelessWidget {
  const _DocsStripShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const AppShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ShimmerBox(height: 96, radius: 10),
              SizedBox(height: 12),
              ShimmerBox(height: 12),
              SizedBox(height: 6),
              ShimmerBox(width: 90, height: 12),
              SizedBox(height: 10),
              ShimmerBox(width: 60, height: 16, radius: 999),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.appBg,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Stack(
        children: <Widget>[
          Center(child: Icon(icon, color: AppColors.brand, size: 36)),
          Positioned(
            left: 10,
            right: 10,
            bottom: 8,
            child: Column(
              children: <Widget>[
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.brand200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 3),
                FractionallySizedBox(
                  widthFactor: 0.7,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.brand200,
                      borderRadius: BorderRadius.circular(2),
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
