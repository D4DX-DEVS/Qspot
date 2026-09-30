import 'package:flutter/material.dart';

import '../../../../themes/auth_palette.dart';

/// Soft layered pink waves along the bottom edge, with a deeper accent
/// rising in the right corner.
class BottomWavesPainter extends CustomPainter {
  BottomWavesPainter(this.palette);

  final AuthPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.3)
        ..cubicTo(w * 0.25, h * 0.05, w * 0.45, h * 0.7, w * 0.7, h * 0.45)
        ..cubicTo(w * 0.85, h * 0.3, w * 0.95, h * 0.25, w, h * 0.15)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = palette.waveSoft,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.65)
        ..cubicTo(w * 0.3, h * 0.4, w * 0.55, h * 0.95, w, h * 0.55)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = palette.waveMid,
    );

    final corner = Path()
      ..moveTo(w * 0.62, h)
      ..cubicTo(w * 0.78, h * 0.85, w * 0.88, h * 0.62, w, h * 0.5)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      corner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [palette.cornerEnd, palette.waveMid],
        ).createShader(corner.getBounds()),
    );
  }

  @override
  bool shouldRepaint(BottomWavesPainter oldDelegate) =>
      oldDelegate.palette != palette;
}
