import 'package:flutter/material.dart';

import '../../../themes/home_palette.dart';
import '../../../widgets/common/tone_chip.dart';
import '../model/chapter_progress.dart';

/// "Start", "Continue" or "Done" pill for a chapter; nothing for a chapter
/// with no lessons yet.
class ChapterStatusChip extends StatelessWidget {
  const ChapterStatusChip({super.key, required this.status});

  final ChapterStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return switch (status) {
      ChapterStatus.empty => const SizedBox.shrink(),
      ChapterStatus.notStarted => ToneChip(label: 'Start', tone: palette.rose),
      ChapterStatus.inProgress => ToneChip(
        label: 'Continue',
        tone: palette.amber,
      ),
      ChapterStatus.completed => ToneChip(label: 'Done', tone: palette.mint),
    };
  }
}
