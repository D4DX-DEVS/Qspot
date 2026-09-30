import 'package:flutter/material.dart';

import '../../../themes/auth_palette.dart';
import '../../auth/widgets/art/mihrab_arch_painter.dart';
import '../../auth/widgets/art/mosque_skyline_painter.dart';

/// Faded night scene behind the splash logo, in the login screen's style: an
/// arch framing the centre and a mosque skyline standing on a floor band that
/// leaves room for a footer line.
class SplashArtwork extends StatelessWidget {
  const SplashArtwork({
    super.key,
    this.palette = AuthPalette.splash,
    this.opacity = 0.4,
    this.footerHeight = 56,
  });

  final AuthPalette palette;

  /// Keeps the scene in the background so the logo stays the focus.
  final double opacity;

  /// Plain floor kept clear under the skyline (plus the bottom safe area).
  final double footerHeight;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final floor = MediaQuery.paddingOf(context).bottom + footerHeight;
    final skylineHeight = (size.height * 0.28).clamp(170.0, 260.0);

    return Opacity(
      opacity: opacity,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: floor,
            child: ColoredBox(color: palette.floor),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: floor,
            height: skylineHeight,
            child: CustomPaint(
              painter: MosqueSkylinePainter(
                palette,
                showBookStand: false,
                showMoon: false,
              ),
            ),
          ),
          // Arch sits a little above centre so the (centred) logo lands in
          // its body, below the pointed top.
          Center(
            child: Transform.translate(
              offset: const Offset(0, -50),
              child: SizedBox(
                width: 280,
                height: 400,
                child: CustomPaint(painter: MihrabArchPainter(palette)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
