import 'package:flutter/material.dart';

import '../../../../themes/auth_palette.dart';

/// Pointed (ogee) arch that frames the logo and headline, fading out at the
/// bottom. Dark mode gets a warm glowing rim from the palette.
class MihrabArchPainter extends CustomPainter {
  MihrabArchPainter(this.palette);

  final AuthPalette palette;

  static Path archPath(Rect r) {
    final w = r.width;
    final h = r.height;
    final cx = r.center.dx;
    final shoulder = r.top + h * 0.45;
    return Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, shoulder)
      ..cubicTo(
        r.left,
        r.top + h * 0.2,
        cx - w * 0.06,
        r.top + h * 0.1,
        cx,
        r.top,
      )
      ..cubicTo(
        cx + w * 0.06,
        r.top + h * 0.1,
        r.right,
        r.top + h * 0.2,
        r.right,
        shoulder,
      )
      ..lineTo(r.right, r.bottom)
      ..close();
  }

  Shader _fade(Rect r, Color color, double fadeAt) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color, color.withValues(alpha: 0)],
      stops: [fadeAt, 1],
    ).createShader(r);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const halo = 14.0;
    final outer = Rect.fromLTWH(0, 0, size.width, size.height);
    final inner = Rect.fromLTRB(halo, halo, size.width - halo, size.height);

    canvas.drawPath(
      archPath(outer),
      Paint()..shader = _fade(outer, palette.archHalo, 0.45),
    );
    final arch = archPath(inner);
    canvas.drawPath(
      arch,
      Paint()..shader = _fade(inner, palette.archFill, 0.6),
    );

    final rim = _fade(inner, palette.archEdge, 0.35);
    canvas.drawPath(
      arch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..shader = rim,
    );
    canvas.drawPath(
      arch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = rim,
    );
  }

  @override
  bool shouldRepaint(MihrabArchPainter oldDelegate) =>
      oldDelegate.palette != palette;
}
