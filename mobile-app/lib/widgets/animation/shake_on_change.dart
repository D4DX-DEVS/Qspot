import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';

/// Wobbles [child] sideways every time [trigger] changes (e.g. a wrong
/// answer). The first build stays still.
class ShakeOnChange extends StatefulWidget {
  const ShakeOnChange({
    super.key,
    required this.trigger,
    required this.child,
    this.distance = 8,
  });

  final Object? trigger;
  final Widget child;

  /// Widest swing in logical pixels.
  final double distance;

  @override
  State<ShakeOnChange> createState() => _ShakeOnChangeState();
}

class _ShakeOnChangeState extends State<ShakeOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(covariant ShakeOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && !Motion.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (_, child) {
        // Three quick swings that fade out.
        final t = _controller.value;
        final dx = math.sin(t * math.pi * 6) * (1 - t) * widget.distance;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
