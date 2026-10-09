import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/animated_progress_bar.dart';
import '../model/chapter_progress.dart';

/// "3/8 Lessons" with a progress bar under it, or a quiet note when the
/// chapter has no lessons yet. Stacked, so the text can wrap at any size.
class ChapterProgressLine extends StatelessWidget {
  const ChapterProgressLine({super.key, required this.progress});

  final ChapterProgress progress;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    if (progress.status == ChapterStatus.empty) {
      return Text(
        'No Lessons Yet',
        style: AppFonts.medium(color: palette.textMuted, fontSize: 12),
      );
    }

    final done = progress.status == ChapterStatus.completed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${progress.completed}/${progress.total} Lessons',
          style: AppFonts.semiBold(color: palette.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 6),
        AnimatedProgressBar(
          minHeight: 6,
          value: progress.fraction,
          borderRadius: BorderRadius.circular(3),
          backgroundColor: palette.brandSoft,
          color: done ? palette.mint.color : palette.brand,
        ),
      ],
    );
  }
}
