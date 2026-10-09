import 'package:flutter/material.dart';

import '../../themes/accent_tone.dart';
import '../../themes/app_fonts.dart';
import '../animation/pressable_scale.dart';

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
      // Raised, outlined and tinted so it reads as a pressable button, not a
      // flat label.
      child: PressableScale(
        pressedScale: 0.92,
        haptic: true,
        child: Material(
          color: tone.soft,
          elevation: 3,
          shadowColor: tone.color.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: tone.color.withValues(alpha: 0.28)),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashColor: tone.color.withValues(alpha: 0.18),
            highlightColor: tone.color.withValues(alpha: 0.1),
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
      ),
    );
  }
}
