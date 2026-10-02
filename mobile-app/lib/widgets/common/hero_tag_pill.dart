import 'package:flutter/material.dart';

import '../../themes/app_colors.dart';
import '../../themes/app_fonts.dart';

/// Small white pill with burgundy text, for tags on a `GradientCard`
/// (e.g. "Class 8"). Same in light and dark, since it sits on the gradient.
class HeroTagPill extends StatelessWidget {
  const HeroTagPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppFonts.semiBold(color: AppColors.authBrand, fontSize: 12),
      ),
    );
  }
}
