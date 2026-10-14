import 'package:flutter/material.dart';

import '../../../themes/accent_tone.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/tone_chip.dart';
import '../../course/model/lesson_status.dart';

/// "LESSON 3 OF 8", the lesson's title, where it sits, and a chip with the
/// learner's progress on it.
class LessonTitleBlock extends StatelessWidget {
  const LessonTitleBlock({
    super.key,
    required this.title,
    required this.subtitle,
    this.positionLabel,
    this.status,
  });

  final String title;
  final String subtitle;
  final String? positionLabel;
  final LessonStatus? status;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final chip = _chip(palette);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (positionLabel != null)
              Expanded(
                child: Text(
                  positionLabel!.toUpperCase(),
                  style: AppFonts.semiBold(
                    color: palette.brand,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              )
            else
              const Spacer(),
            if (chip != null) ToneChip(label: chip.$1, tone: chip.$2),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: AppFonts.bold(color: palette.text, fontSize: 20, height: 1.25),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppFonts.regular(color: palette.textMuted, fontSize: 12.5),
          ),
        ],
      ],
    );
  }

  (String, AccentTone)? _chip(HomePalette palette) => switch (status) {
    LessonStatus.completed => ('Done', palette.mint),
    LessonStatus.inProgress => ('In Progress', palette.rose),
    LessonStatus.upNext => ('Not Started', palette.amber),
    LessonStatus.locked => ('Locked', palette.slate),
    LessonStatus.upcoming => ('Soon', palette.slate),
    null => null,
  };
}
