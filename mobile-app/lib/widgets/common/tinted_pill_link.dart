import 'package:flutter/material.dart';

import '../../themes/accent_tone.dart';
import '../../themes/app_fonts.dart';

/// Small soft pill with a label and an arrow, e.g. "Open assignments ->".
class TintedPillLink extends StatelessWidget {
  const TintedPillLink({
    super.key,
    required this.label,
    required this.tone,
    this.onTap,
  });

  final String label;
  final AccentTone tone;

  /// Leave null when the surrounding card already handles the tap.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Material(
      color: tone.soft,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppFonts.semiBold(color: tone.color, fontSize: 12.5),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, color: tone.color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
