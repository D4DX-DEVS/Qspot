import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';

/// Pinned bar under a lesson: go back a lesson, see the lesson list, go on to
/// the next. Next stays shut, with a note, until the lesson is finished.
class LessonNavBar extends StatelessWidget {
  const LessonNavBar({
    super.key,
    required this.hasPrevious,
    required this.hasNext,
    required this.canOpenNext,
    required this.onPrevious,
    required this.onLessons,
    required this.onNext,
    this.nextHint,
  });

  final bool hasPrevious;
  final bool hasNext;
  final bool canOpenNext;
  final VoidCallback onPrevious;
  final VoidCallback onLessons;
  final VoidCallback onNext;

  /// Why Next is shut, shown above the buttons.
  final String? nextHint;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(top: BorderSide(color: palette.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (nextHint != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    nextHint!,
                    textAlign: TextAlign.center,
                    style: AppFonts.medium(
                      color: palette.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              Row(
                children: [
                  // Labels shrink to fit, so the bar holds at the narrowest phone
                  // and the largest text size.
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      style: _outlined(palette),
                      onPressed: hasPrevious ? onPrevious : null,
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Previous'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      style: _outlined(palette),
                      onPressed: onLessons,
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.list, size: 16),
                            SizedBox(width: 6),
                            Text('Lessons'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.brand,
                        foregroundColor: palette.card,
                        minimumSize: const Size(0, 48),
                        textStyle: AppFonts.semiBold(fontSize: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: hasNext && canOpenNext ? onNext : null,
                      child: const Text('Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _outlined(HomePalette palette) => OutlinedButton.styleFrom(
    foregroundColor: palette.brand,
    minimumSize: const Size(0, 48),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    textStyle: AppFonts.semiBold(fontSize: 13),
    side: BorderSide(color: palette.cardBorder),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
