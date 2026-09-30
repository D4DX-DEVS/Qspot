import 'package:flutter/material.dart';

import '../../themes/app_fonts.dart';

/// Icon button with a small count badge in its top-right corner. The badge
/// hides when [count] is 0 and caps at "9+".
class BadgedIconButton extends StatelessWidget {
  const BadgedIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.count = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          icon: Icon(icon, color: scheme.onSurface, size: 26),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 4,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: scheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 1.5),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  textAlign: TextAlign.center,
                  style: AppFonts.bold(color: scheme.onError, fontSize: 9),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
