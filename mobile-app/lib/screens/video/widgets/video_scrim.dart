import 'package:flutter/material.dart';

import '../../../themes/app_colors.dart';

/// Dark fade laid over the edge of a video so white text stays readable on
/// any frame. Fades from dark at the top edge when [fromTop] is true, otherwise
/// from dark at the bottom edge. Touches pass through.
class VideoScrim extends StatelessWidget {
  const VideoScrim({super.key, required this.height, this.fromTop = false});

  final double height;
  final bool fromTop;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: fromTop ? Alignment.bottomCenter : Alignment.topCenter,
            end: fromTop ? Alignment.topCenter : Alignment.bottomCenter,
            colors: const [AppColors.transparent, AppColors.scrim],
          ),
        ),
      ),
    );
  }
}
