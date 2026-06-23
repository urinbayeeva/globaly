import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FlagChip extends StatelessWidget {
  const FlagChip({
    super.key,
    this.bands = const <Color>[
      Colors.black,
      Color(0xFFDD0000),
      Color(0xFFFFCE00),
    ],
    this.width = 36,
    this.height = 26,
  });

  final List<Color> bands;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.gray300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Column(
          children: bands
              .map((Color c) => Expanded(child: Container(color: c)))
              .toList(),
        ),
      ),
    );
  }
}
