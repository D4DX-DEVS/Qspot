import 'package:flutter/material.dart';

import 'motion.dart';

/// `LinearProgressIndicator` that fills up from empty when it first shows and
/// glides whenever [value] changes.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.minHeight,
    this.color,
    this.backgroundColor,
    this.borderRadius = BorderRadius.zero,
  });

  /// 0 to 1.
  final double value;
  final double? minHeight;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: Motion.reduced(context) ? Duration.zero : Motion.slow,
      curve: Motion.smooth,
      builder: (_, v, __) => LinearProgressIndicator(
        value: v,
        minHeight: minHeight,
        color: color,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
      ),
    );
  }
}
