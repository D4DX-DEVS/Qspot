import 'package:flutter/material.dart';

import '../../auth/widgets/art/auth_art.dart';
import '../../auth/widgets/art/hanging_lantern_painter.dart';
import 'art/book_stack_painter.dart';

/// Corner artwork for the Learn banner: a glowing lantern hung from the top
/// edge beside a small stack of books. Fills its (bounded) parent.
class LearnBannerArt extends StatelessWidget {
  const LearnBannerArt({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 18,
          top: 0,
          width: 46,
          height: 96,
          child: AuthArt(painter: (palette) => HangingLanternPainter(palette)),
        ),
        Positioned(
          right: 58,
          bottom: 10,
          width: 74,
          height: 52,
          child: AuthArt(painter: (palette) => BookStackPainter(palette)),
        ),
      ],
    );
  }
}
