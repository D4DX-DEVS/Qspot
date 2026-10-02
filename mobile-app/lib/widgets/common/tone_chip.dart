import 'package:flutter/material.dart';

import '../../themes/accent_tone.dart';
import '../../themes/app_fonts.dart';

/// Small rounded status label on the soft tint of an accent [tone].
class ToneChip extends StatelessWidget {
  const ToneChip({super.key, required this.label, required this.tone});

  final String label;
  final AccentTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppFonts.semiBold(color: tone.color, fontSize: 12),
      ),
    );
  }
}
