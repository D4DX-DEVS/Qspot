import 'package:flutter/material.dart';

import '../../themes/accent_tone.dart';
import '../../themes/app_fonts.dart';

/// Quiet tinted note: an icon beside a short sentence, in the given [tone].
class InfoNoteCard extends StatelessWidget {
  const InfoNoteCard({
    super.key,
    required this.icon,
    required this.tone,
    required this.message,
  });

  final IconData icon;
  final AccentTone tone;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tone.color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppFonts.regular(
                color: scheme.onSurface,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
