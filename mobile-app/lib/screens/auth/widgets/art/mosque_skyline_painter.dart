import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../themes/app_colors.dart';
import '../../../../themes/auth_palette.dart';

/// Flat mosque skyline (domes, minarets, palms, crescent) for the bottom of
/// the auth screens, optionally with an open Qur'ān on a rehal in front.
/// With [showSkyline] off, only the book stand is drawn, filling the box.
class MosqueSkylinePainter extends CustomPainter {
  MosqueSkylinePainter(
    this.palette, {
    this.showBookStand = true,
    this.showMoon = true,
    this.showSkyline = true,
  });

  final AuthPalette palette;
  final bool showBookStand;
  final bool showMoon;
  final bool showSkyline;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (!showSkyline) {
      if (showBookStand) _bookStand(canvas, w / 2, h * 0.35, w * 0.95, h);
      return;
    }
    final ground = h * (showBookStand ? 0.72 : 0.9);
    final cx = w / 2;

    canvas.drawRect(
      Rect.fromLTRB(0, ground, w, h),
      Paint()..color = palette.floor,
    );
    _mosque(canvas, w, ground, cx);
    for (final side in [-1.0, 1.0]) {
      _palm(canvas, Offset(cx + side * w * 0.43, ground), side, ground);
    }

    // Fade the tops of the buildings into the page.
    canvas.drawRect(
      Rect.fromLTRB(0, 0, w, ground),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.background.withValues(alpha: 0.7),
            palette.background.withValues(alpha: 0),
          ],
          stops: const [0, 0.4],
        ).createShader(Rect.fromLTRB(0, 0, w, ground)),
    );

    if (showMoon) {
      _crescent(canvas, Offset(cx - w * 0.08, ground * 0.2), ground * 0.09);
    }
    if (showBookStand) _bookStand(canvas, cx, ground, w * 0.42, h);
  }

  void _mosque(Canvas canvas, double w, double ground, double cx) {
    final far = Paint()..color = palette.skylineFar;
    final g = ground;

    // Outer minarets, inner minarets.
    for (final side in [-1.0, 1.0]) {
      _minaret(canvas, cx + side * w * 0.36, g, g * 0.55, w * 0.026, far);
      _minaret(canvas, cx + side * w * 0.24, g, g * 0.78, w * 0.032, far);
      _dome(
        canvas,
        cx + side * w * 0.15,
        g - g * 0.18,
        w * 0.055,
        g * 0.16,
        far,
      );
      canvas.drawRect(
        Rect.fromLTRB(
          cx + side * w * 0.15 - w * 0.05,
          g - g * 0.19,
          cx + side * w * 0.15 + w * 0.05,
          g,
        ),
        far,
      );
    }

    canvas.drawRect(
      Rect.fromLTRB(cx - w * 0.33, g - g * 0.14, cx + w * 0.33, g),
      far,
    );
    canvas.drawRect(
      Rect.fromLTRB(cx - w * 0.12, g - g * 0.32, cx + w * 0.12, g),
      far,
    );
    _dome(canvas, cx, g - g * 0.31, w * 0.13, g * 0.32, far);
    canvas.drawRect(
      Rect.fromLTRB(cx - 1, g - g * 0.7, cx + 1, g - g * 0.62),
      far,
    );

    // Arched windows on the prayer hall and side wings.
    final window = Paint()..color = palette.window;
    for (final dx in [-0.07, 0.0, 0.07]) {
      _archWindow(
        canvas,
        cx + dx * w,
        g - g * 0.06,
        w * 0.022,
        g * 0.15,
        window,
      );
    }
    for (final dx in [-0.27, -0.21, 0.21, 0.27]) {
      _archWindow(
        canvas,
        cx + dx * w,
        g - g * 0.03,
        w * 0.014,
        g * 0.07,
        window,
      );
    }
  }

  /// Onion dome sitting on [baseY], [halfWidth] wide each side.
  void _dome(
    Canvas canvas,
    double x,
    double baseY,
    double halfWidth,
    double height,
    Paint paint,
  ) {
    canvas.drawPath(
      Path()
        ..moveTo(x - halfWidth, baseY)
        ..cubicTo(
          x - halfWidth * 1.2,
          baseY - height * 0.6,
          x - halfWidth * 0.25,
          baseY - height * 0.75,
          x,
          baseY - height,
        )
        ..cubicTo(
          x + halfWidth * 0.25,
          baseY - height * 0.75,
          x + halfWidth * 1.2,
          baseY - height * 0.6,
          x + halfWidth,
          baseY,
        )
        ..close(),
      paint,
    );
  }

  void _minaret(
    Canvas canvas,
    double x,
    double ground,
    double height,
    double width,
    Paint paint,
  ) {
    final top = ground - height;
    canvas.drawRect(
      Rect.fromLTRB(x - width / 2, top, x + width / 2, ground),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        x - width * 0.85,
        top + height * 0.28,
        x + width * 0.85,
        top + height * 0.32,
      ),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(x - width * 0.65, top)
        ..lineTo(x, top - height * 0.16)
        ..lineTo(x + width * 0.65, top)
        ..close(),
      paint,
    );
  }

  void _archWindow(
    Canvas canvas,
    double x,
    double bottom,
    double halfWidth,
    double height,
    Paint paint,
  ) {
    canvas.drawPath(
      Path()
        ..moveTo(x - halfWidth, bottom)
        ..lineTo(x - halfWidth, bottom - height + halfWidth)
        ..quadraticBezierTo(x - halfWidth, bottom - height, x, bottom - height)
        ..quadraticBezierTo(
          x + halfWidth,
          bottom - height,
          x + halfWidth,
          bottom - height + halfWidth,
        )
        ..lineTo(x + halfWidth, bottom)
        ..close(),
      paint,
    );
  }

  /// Palm leaning away from the centre ([side] is -1 left, 1 right).
  void _palm(Canvas canvas, Offset base, double side, double ground) {
    final height = ground * 0.55;
    final top = base + Offset(side * height * 0.1, -height);

    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(
          base.dx - side * height * 0.05,
          base.dy - height * 0.55,
          top.dx,
          top.dy,
        ),
      Paint()
        ..color = palette.skylineNear
        ..style = PaintingStyle.stroke
        ..strokeWidth = height * 0.06
        ..strokeCap = StrokeCap.round,
    );

    // Filled, drooping fronds fanned from straight left to straight right.
    final leaf = Paint()..color = palette.skylineNear;
    final reach = height * 0.5;
    for (final degrees in const [-175, -150, -120, -90, -60, -30, -5]) {
      final angle = degrees * math.pi / 180;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final normal = Offset(-dir.dy, dir.dx);
      final tip = top + dir * reach + Offset(0, reach * 0.4 * dir.dx.abs());
      final mid = top + dir * (reach * 0.55) - Offset(0, reach * 0.1);
      final upper = mid + normal * (reach * 0.12);
      final lower = mid - normal * (reach * 0.12);
      canvas.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(upper.dx, upper.dy, tip.dx, tip.dy)
          ..quadraticBezierTo(lower.dx, lower.dy, top.dx, top.dy),
        leaf,
      );
    }
  }

  void _crescent(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius * 1.8,
      Paint()
        ..color = palette.moon.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius),
    );
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
        Path()..addOval(
          Rect.fromCircle(
            center: center + Offset(radius * 0.45, -radius * 0.25),
            radius: radius * 0.85,
          ),
        ),
      ),
      Paint()..color = palette.moon,
    );
  }

  /// Open book on a cross-legged wooden stand, centred on [cx].
  void _bookStand(
    Canvas canvas,
    double cx,
    double ground,
    double bw,
    double h,
  ) {
    final bh = bw * 0.22;
    final y = ground + (h - ground) * 0.25;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.96),
        width: bw * 0.9,
        height: bh * 0.35,
      ),
      Paint()
        ..color = AppColors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final wood = Paint()
      ..color = palette.wood
      ..strokeWidth = bw * 0.05
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - bw * 0.3, h * 0.97),
      Offset(cx + bw * 0.2, y),
      wood,
    );
    canvas.drawLine(
      Offset(cx + bw * 0.3, h * 0.97),
      Offset(cx - bw * 0.2, y),
      wood,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx - bw * 0.5, y - bh * 0.32)
        ..lineTo(cx, y + bh * 0.3)
        ..lineTo(cx + bw * 0.5, y - bh * 0.32)
        ..lineTo(cx + bw * 0.5, y - bh * 0.05)
        ..lineTo(cx, y + bh * 0.62)
        ..lineTo(cx - bw * 0.5, y - bh * 0.05)
        ..close(),
      Paint()..color = palette.wood,
    );

    final line = Paint()
      ..color = palette.wood.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    for (final side in [-1.0, 1.0]) {
      final topOuter = Offset(cx + side * bw * 0.45, y - bh * 0.75);
      final bottomOuter = Offset(cx + side * bw * 0.47, y - bh * 0.25);
      canvas.drawPath(
        Path()
          ..moveTo(cx, y + bh * 0.35)
          ..quadraticBezierTo(
            cx + side * bw * 0.25,
            y + bh * 0.05,
            bottomOuter.dx,
            bottomOuter.dy,
          )
          ..lineTo(topOuter.dx, topOuter.dy)
          ..quadraticBezierTo(
            cx + side * bw * 0.22,
            y - bh * 0.55,
            cx,
            y - bh * 0.15,
          )
          ..close(),
        Paint()..color = palette.pages,
      );
      // A few lines of text on each page.
      for (final t in const [0.3, 0.5, 0.7]) {
        final outer = Offset.lerp(topOuter, bottomOuter, t)!;
        final inner = Offset.lerp(
          Offset(cx, y - bh * 0.15),
          Offset(cx, y + bh * 0.35),
          t,
        )!;
        canvas.drawLine(
          Offset.lerp(outer, inner, 0.12)!,
          Offset.lerp(outer, inner, 0.85)!,
          line,
        );
      }
    }
  }

  @override
  bool shouldRepaint(MosqueSkylinePainter oldDelegate) =>
      oldDelegate.palette != palette ||
      oldDelegate.showBookStand != showBookStand ||
      oldDelegate.showMoon != showMoon ||
      oldDelegate.showSkyline != showSkyline;
}
