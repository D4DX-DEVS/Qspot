import 'package:flutter/material.dart';

import '../../themes/home_palette.dart';

/// Rounded burgundy hero surface. Optional [art] is pinned to the
/// bottom-right corner behind [child] and clipped to the card.
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.art,
    this.backdrop,
    this.artSize = const Size(140, 120),
    this.padding = const EdgeInsets.all(20),
    this.minHeight = 0,
    this.gradient,
  });

  final Widget child;
  final Widget? art;

  /// Fills the whole card behind everything else (e.g. a photo with a scrim).
  final Widget? backdrop;
  final Size artSize;
  final EdgeInsetsGeometry padding;
  final double minHeight;

  /// Defaults to the palette's hero gradient.
  final Gradient? gradient;

  static const double radius = 22;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: gradient ?? palette.heroGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: palette.brand.withValues(
              alpha: palette.isDark ? 0.18 : 0.24,
            ),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (backdrop != null) Positioned.fill(child: backdrop!),
          if (art != null)
            Positioned(
              right: 0,
              bottom: 0,
              width: artSize.width,
              height: artSize.height,
              child: IgnorePointer(child: art!),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
