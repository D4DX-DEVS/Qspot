import 'package:flutter/material.dart';

import '../../../themes/home_palette.dart';
import '../../auth/widgets/art/auth_art.dart';
import '../../auth/widgets/art/mosque_skyline_painter.dart';

/// "No connection" picture: a Wi-Fi mark with a cross badge in a soft
/// circle, over a faint mosque skyline.
class OfflineIllustration extends StatelessWidget {
  const OfflineIllustration({super.key, this.width = 280, this.height = 200});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final circle = height * 0.72;
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: height * 0.5,
              child: Opacity(
                opacity: 0.45,
                child: AuthArt(
                  painter: (art) => MosqueSkylinePainter(
                    art,
                    showBookStand: false,
                    showMoon: false,
                  ),
                ),
              ),
            ),
            Container(
              width: circle,
              height: circle,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [palette.card, palette.brandSoft],
                ),
                border: Border.all(color: palette.cardBorder),
              ),
              child: Icon(
                Icons.wifi_rounded,
                color: palette.brand,
                size: circle * 0.48,
              ),
            ),
            Positioned(
              left: width / 2 + circle * 0.12,
              top: height / 2 + circle * 0.06,
              child: Container(
                width: circle * 0.24,
                height: circle * 0.24,
                decoration: BoxDecoration(
                  color: palette.brand,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.card, width: 2.5),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: palette.card,
                  size: circle * 0.16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
