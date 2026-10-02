import 'package:flutter/material.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';

/// Dark pill with a chapter number, readable on top of any cover picture.
class ChapterNumberBadge extends StatelessWidget {
  const ChapterNumberBadge({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        '$number',
        style: AppFonts.bold(color: AppColors.white, fontSize: 12),
      ),
    );
  }
}
