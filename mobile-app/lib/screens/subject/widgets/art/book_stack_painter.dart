import 'package:flutter/material.dart';

import '../../../../themes/auth_palette.dart';

/// Three closed books stacked on their sides, each with a page block and a
/// gold band on the spine. Fills its box.
class BookStackPainter extends CustomPainter {
  BookStackPainter(this.palette);

  final AuthPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawOval(
      Rect.fromLTWH(w * 0.02, h * 0.9, w * 0.96, h * 0.12),
      Paint()
        ..color = palette.wood.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    _book(canvas, Rect.fromLTWH(0, h * 0.64, w, h * 0.32), palette.wood);
    _book(
      canvas,
      Rect.fromLTWH(w * 0.08, h * 0.34, w * 0.86, h * 0.3),
      palette.lanternFrame,
    );
    _book(
      canvas,
      Rect.fromLTWH(w * 0.02, h * 0.06, w * 0.8, h * 0.28),
      palette.archEdge,
    );
  }

  void _book(Canvas canvas, Rect cover, Color color) {
    final radius = Radius.circular(cover.height * 0.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cover, radius),
      Paint()..color = color,
    );

    // Page block showing on the right, inset from the covers.
    final inset = cover.height * 0.16;
    final pages = Rect.fromLTRB(
      cover.left + cover.width * 0.16,
      cover.top + inset,
      cover.right - 2,
      cover.bottom - inset,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        pages,
        topRight: Radius.circular(inset),
        bottomRight: Radius.circular(inset),
      ),
      Paint()..color = palette.pages,
    );

    final line = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 0.8;
    for (final t in const [0.35, 0.65]) {
      final y = pages.top + pages.height * t;
      canvas.drawLine(
        Offset(pages.left + 4, y),
        Offset(pages.right - 3, y),
        line,
      );
    }

    // Gold band across the spine.
    final bandX = cover.left + cover.width * 0.07;
    canvas.drawLine(
      Offset(bandX, cover.top + 2),
      Offset(bandX, cover.bottom - 2),
      Paint()
        ..color = palette.lanternGlow
        ..strokeWidth = cover.width * 0.025,
    );
  }

  @override
  bool shouldRepaint(BookStackPainter oldDelegate) =>
      oldDelegate.palette != palette;
}
