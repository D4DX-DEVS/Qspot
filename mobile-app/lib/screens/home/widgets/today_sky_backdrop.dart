import 'package:flutter/material.dart';

import '../../../themes/home_palette.dart';
import '../../auth/widgets/art/auth_art.dart';
import '../../auth/widgets/art/mosque_skyline_painter.dart';

/// Warm sky fading into the page with a soft mosque skyline, drawn behind
/// the Today greeting. Fills its (bounded) parent.
class TodaySkyBackdrop extends StatelessWidget {
  const TodaySkyBackdrop({super.key, this.skylineOpacity = 0.9});

  final double skylineOpacity;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.skyTop, palette.background],
          stops: const [0.15, 0.95],
        ),
      ),
      // The skyline fills the whole box so its own top fade starts at the
      // top edge instead of leaving a band mid-sky.
      child: Opacity(
        // The night skyline's lit windows are loud; keep it further back.
        opacity: palette.isDark ? skylineOpacity * 0.65 : skylineOpacity,
        child: AuthArt(
          painter: (art) =>
              MosqueSkylinePainter(art, showBookStand: false, showMoon: false),
        ),
      ),
    );
  }
}
