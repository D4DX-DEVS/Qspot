import 'package:flutter/material.dart';

import '../../../../themes/auth_palette.dart';

/// Layered burgundy wave that sweeps into the top-right corner.
class CornerWavePainter extends CustomPainter {
  CornerWavePainter(this.palette);

  final AuthPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.3, 0)
        ..cubicTo(w * 0.46, h * 0.05, w * 0.5, h * 0.42, w * 0.72, h * 0.5)
        ..cubicTo(w * 0.88, h * 0.56, w * 0.95, h * 0.8, w, h)
        ..lineTo(w, 0)
        ..close(),
      Paint()..color = palette.cornerEnd.withValues(alpha: 0.3),
    );

    final front = Path()
      ..moveTo(w * 0.44, 0)
      ..cubicTo(w * 0.56, h * 0.02, w * 0.6, h * 0.3, w * 0.77, h * 0.38)
      ..cubicTo(w * 0.9, h * 0.44, w * 0.96, h * 0.62, w, h * 0.82)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(
      front,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [palette.cornerStart, palette.cornerEnd],
        ).createShader(front.getBounds()),
    );
  }

  @override
  bool shouldRepaint(CornerWavePainter oldDelegate) =>
      oldDelegate.palette != palette;
}
