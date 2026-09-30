import 'package:flutter/material.dart';

import '../../themes/app_fonts.dart';

/// Rounded outlined button in the brand colour on the card surface, e.g.
/// "Try again" or "Logout". Stretches to the available width when [expand].
class SoftOutlineButton extends StatelessWidget {
  const SoftOutlineButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.expand = false,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool expand;

  /// Defaults to the theme's primary colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = color ?? scheme.primary;
    final button = OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: AppFonts.semiBold(fontSize: 15)),
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        backgroundColor: scheme.surfaceContainerLow,
        side: BorderSide(color: ink.withValues(alpha: 0.35), width: 1.4),
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
