import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

class FamilySection extends StatelessWidget {
  const FamilySection({super.key, required this.country});
  final String country;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFEECEE), Color(0xFFFFF6E5)],
        ),
        border: Border.all(color: AppColors.brand200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0A0D1424),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: const Center(
              child: Text('🤍', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            T.of(context, 'family.goodLuck'),
            style: AppTypography.h2.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            country.isEmpty
                ? T.of(context, 'family.noteGeneric')
                : T.of(context, 'family.note').replaceAll('{0}', country),
            style: AppTypography.bodyL.copyWith(
              color: AppColors.gray800,
              height: 22 / 14,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              const Icon(
                Icons.favorite_rounded,
                size: 14,
                color: AppColors.brand,
              ),
              const SizedBox(width: 6),
              Text(
                T.of(context, 'family.from'),
                style: AppTypography.caption.copyWith(
                  color: AppColors.brand700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
