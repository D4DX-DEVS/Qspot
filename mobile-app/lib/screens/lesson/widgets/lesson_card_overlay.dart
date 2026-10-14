import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/home_palette.dart';

/// Puts a lesson number on the corner of a card and, for a locked lesson,
/// dims the card and shows a lock. Taps still reach the card underneath.
class LessonCardOverlay extends StatelessWidget {
  const LessonCardOverlay({
    super.key,
    required this.child,
    this.number,
    this.locked = false,
  });

  final Widget child;

  /// 1-based position inside the chapter. No badge when null.
  final int? number;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Stack(
      children: [
        child,
        if (locked)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.background.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                    child: const Icon(
                      LucideIcons.lock,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (number != null)
          Positioned(
            top: 8,
            left: 8,
            child: IgnorePointer(
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.brand,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  '$number',
                  style: AppFonts.bold(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
