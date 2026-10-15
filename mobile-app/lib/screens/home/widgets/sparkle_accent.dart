import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_colors.dart';
import '../../../widgets/animation/motion.dart';

/// A large and a small gold sparkle, placed after a hero title.
class SparkleAccent extends StatelessWidget {
  const SparkleAccent({super.key, this.size = 24});

  final double size;

  // Light end of the gold pill gradient.
  static final Color _gold = AppColors.homeGoldGradient.colors.first;

  @override
  Widget build(BuildContext context) {
    // Pops in once, then rests.
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Motion.reduced(context) ? Duration.zero : Motion.slow,
        curve: Motion.bounce,
        builder: (_, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.sparkles, color: _gold, size: size),
            Padding(
              padding: EdgeInsets.only(top: size * 0.1),
              child: Icon(
                LucideIcons.sparkles,
                color: _gold.withValues(alpha: 0.7),
                size: size * 0.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
