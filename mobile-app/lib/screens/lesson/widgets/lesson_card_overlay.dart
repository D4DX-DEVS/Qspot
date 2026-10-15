import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';

/// Puts a lesson number on the corner of a card. Taps still reach the card
/// underneath.
class LessonCardOverlay extends StatelessWidget {
  const LessonCardOverlay({super.key, required this.child, this.number});

  final Widget child;

  /// 1-based position inside the chapter. No badge when null.
  final int? number;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Stack(
      children: [
        child,
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
