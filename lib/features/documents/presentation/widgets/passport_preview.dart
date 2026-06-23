import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class PassportPreview extends StatelessWidget {
  const PassportPreview({super.key, this.icon = Icons.book_rounded});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.appBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0F0D1424),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 64,
                  height: 80,
                  color: AppColors.gray100,
                  child: Icon(
                    icon,
                    color: AppColors.gray400,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "PASSPORT · O'ZBEKISTON",
                        style: TextStyle(
                          fontFamily: AppTypography.family,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          letterSpacing: 0.6,
                        ),
                      ),
                      SizedBox(height: 6),
                      _HighlightLine(text: 'Surname: KARIMOV', warning: false),
                      SizedBox(height: 3),
                      _HighlightLine(text: 'Given: AZIZ', warning: false),
                      SizedBox(height: 3),
                      _HighlightLine(
                        text: 'Date of birth: 14 MAR 1996',
                        warning: false,
                      ),
                      SizedBox(height: 3),
                      _HighlightLine(
                        text: 'Date of expiry: 12 APR 2031',
                        warning: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 24,
          right: -2,
          child: Transform.rotate(
            angle: 0.14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'EXAMPLE',
                style: AppTypography.micro.copyWith(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HighlightLine extends StatelessWidget {
  const _HighlightLine({required this.text, required this.warning});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: warning ? AppColors.alert100 : AppColors.warning100,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AppTypography.family,
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
          height: 1.5,
        ),
      ),
    );
  }
}
