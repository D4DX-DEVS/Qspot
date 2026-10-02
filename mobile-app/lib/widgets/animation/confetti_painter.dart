import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'confetti_particle.dart';

/// Draws [particles] at animation time [t] (0 to 1): they shoot up from the
/// bottom centre, then arc back down under gravity while fading out.
class ConfettiPainter extends CustomPainter {
  const ConfettiPainter({required this.particles, required this.t});

  final List<ConfettiParticle> particles;
  final double t;

  static const double _gravity = 1.9;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height);
    final paint = Paint();
    for (final p in particles) {
      final dx = math.cos(p.angle) * p.speed * size.height * t;
      final dy =
          math.sin(p.angle) * p.speed * size.height * t +
          _gravity * size.height * t * t * 0.5;
      final fade = (1 - ((t - 0.55) / 0.45)).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(origin.dx + dx, origin.dy + dy);
      canvas.rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.55,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldPainter) =>
      oldPainter.t != t || oldPainter.particles != particles;
}
