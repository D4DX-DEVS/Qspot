import 'package:flutter/material.dart';

import '../../../../themes/auth_palette.dart';

/// Small hanging lantern with a soft glow, hung from the top of its box.
class HangingLanternPainter extends CustomPainter {
  HangingLanternPainter(this.palette);

  final AuthPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final frame = Paint()..color = palette.lanternFrame;
    final bodyCenter = Offset(cx, h * 0.65);

    canvas.drawCircle(
      bodyCenter,
      w * 1.3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.lanternGlow.withValues(alpha: 0.55),
            palette.lanternGlow.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: bodyCenter, radius: w * 1.3)),
    );

    canvas.drawLine(
      Offset(cx, 0),
      Offset(cx, h * 0.4),
      Paint()
        ..color = palette.lanternFrame
        ..strokeWidth = 1.2,
    );

    // Domed cap.
    canvas.drawPath(
      Path()
        ..moveTo(cx - w * 0.3, h * 0.48)
        ..quadraticBezierTo(cx - w * 0.2, h * 0.4, cx, h * 0.38)
        ..quadraticBezierTo(cx + w * 0.2, h * 0.4, cx + w * 0.3, h * 0.48)
        ..close(),
      frame,
    );

    final body = Rect.fromLTRB(
      cx - w * 0.34,
      h * 0.48,
      cx + w * 0.34,
      h * 0.82,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(w * 0.12)),
      frame,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        body.deflate(w * 0.08),
        Radius.circular(w * 0.08),
      ),
      Paint()..color = palette.lanternGlow,
    );
    final bar = Paint()
      ..color = palette.lanternFrame
      ..strokeWidth = 1.2;
    for (final dx in [-w * 0.1, w * 0.1]) {
      canvas.drawLine(
        Offset(cx + dx, body.top + w * 0.08),
        Offset(cx + dx, body.bottom - w * 0.08),
        bar,
      );
    }

    // Base and finial.
    canvas.drawPath(
      Path()
        ..moveTo(cx - w * 0.3, h * 0.82)
        ..lineTo(cx + w * 0.3, h * 0.82)
        ..lineTo(cx + w * 0.12, h * 0.89)
        ..lineTo(cx - w * 0.12, h * 0.89)
        ..close(),
      frame,
    );
    canvas.drawCircle(Offset(cx, h * 0.93), w * 0.06, frame);
  }

  @override
  bool shouldRepaint(HangingLanternPainter oldDelegate) =>
      oldDelegate.palette != palette;
}
