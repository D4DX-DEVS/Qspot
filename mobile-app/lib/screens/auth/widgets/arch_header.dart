import 'package:flutter/material.dart';

import 'art/auth_art.dart';
import 'art/hanging_lantern_painter.dart';
import 'art/mihrab_arch_painter.dart';

/// Header framed by a pointed arch with a hanging lantern, with an optional
/// [leading] control (such as a back button) in the top-left corner.
class ArchHeader extends StatelessWidget {
  const ArchHeader({super.key, required this.child, this.leading});

  final Widget child;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          top: 0,
          left: -12,
          right: -12,
          bottom: 0,
          child: AuthArt(painter: MihrabArchPainter.new),
        ),
        const Positioned(
          top: 0,
          right: 8,
          width: 30,
          height: 110,
          child: AuthArt(painter: HangingLanternPainter.new),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 28),
          child: child,
        ),
        if (leading != null) Positioned(top: 0, left: 0, child: leading!),
      ],
    );
  }
}
