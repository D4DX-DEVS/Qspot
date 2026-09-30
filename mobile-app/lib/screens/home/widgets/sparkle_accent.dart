import 'package:flutter/material.dart';

import '../../../themes/app_colors.dart';

/// A large and a small gold sparkle, placed after a hero title.
class SparkleAccent extends StatelessWidget {
  const SparkleAccent({super.key, this.size = 24});

  final double size;

  // Light end of the gold pill gradient.
  static final Color _gold = AppColors.homeGoldGradient.colors.first;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: _gold, size: size),
          Padding(
            padding: EdgeInsets.only(top: size * 0.1),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: _gold.withValues(alpha: 0.7),
              size: size * 0.55,
            ),
          ),
        ],
      ),
    );
  }
}
