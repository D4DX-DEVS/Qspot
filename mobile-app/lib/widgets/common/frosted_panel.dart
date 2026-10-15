import 'dart:ui';

import 'package:flutter/material.dart';

import '../../themes/home_palette.dart';

/// Frosted-glass surface: blurs whatever is behind it and lays a translucent
/// theme tint and hairline border on top.
class FrostedPanel extends StatelessWidget {
  const FrostedPanel({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.color,
    this.opacity = 0.7,
    this.blur = 20,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// Tint laid over the blur. Defaults to the theme's card colour.
  final Color? color;

  /// Strength of the tint: lower shows more of what is behind.
  final double opacity;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (color ?? p.card).withValues(alpha: opacity),
            borderRadius: borderRadius,
            border: Border.all(color: p.card.withValues(alpha: 0.6)),
          ),
          child: child,
        ),
      ),
    );
  }
}
