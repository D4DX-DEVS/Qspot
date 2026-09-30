import 'package:flutter/material.dart';

import '../../themes/accent_tone.dart';
import '../../themes/app_fonts.dart';

/// Tinted square shortcut: icon over a short label, in the given [tone].
class ShortcutTile extends StatelessWidget {
  const ShortcutTile({
    super.key,
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final AccentTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(16);
    return Semantics(
      label: label,
      button: true,
      excludeSemantics: true,
      child: Material(
        color: tone.soft,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            child: Column(
              children: [
                Icon(icon, color: tone.color, size: 25),
                const SizedBox(height: 8),
                // Long labels ("Assignments") shrink to fit instead of
                // being cut off.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: AppFonts.semiBold(
                      color: scheme.onSurface,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
