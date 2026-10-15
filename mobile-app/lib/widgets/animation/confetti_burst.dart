import 'package:flutter/material.dart';

import 'confetti_painter.dart';
import 'confetti_particle.dart';
import 'motion.dart';

/// One-shot confetti fountain that fills its parent. Plays once as soon as it
/// is built and ignores touches. Skipped when the user turned animations off.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.colors, this.count = 36});

  /// Defaults to the theme's accent colours.
  final List<Color>? colors;
  final int count;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<ConfettiParticle>? _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_particles != null || Motion.reduced(context)) return;
    final scheme = Theme.of(context).colorScheme;
    _particles = ConfettiParticle.generate(
      count: widget.count,
      palette:
          widget.colors ??
          [
            scheme.primary,
            scheme.secondary,
            scheme.tertiary,
            const Color(0xFFFFC107),
            const Color(0xFFFF7A59),
          ],
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final particles = _particles;
    if (particles == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: ConfettiPainter(particles: particles, t: _controller.value),
        ),
      ),
    );
  }
}
