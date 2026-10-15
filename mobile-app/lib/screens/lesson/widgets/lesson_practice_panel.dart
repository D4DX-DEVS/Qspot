import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/info_note_card.dart';
import '../../video/widgets/episode_empty_note.dart';

/// The lesson's practice questions: how many there are, a lock note until the
/// lesson is finished, then a start button.
class LessonPracticePanel extends StatelessWidget {
  const LessonPracticePanel({
    super.key,
    required this.questionCount,
    required this.unlocked,
    required this.onStart,
  });

  final int questionCount;
  final bool unlocked;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    if (questionCount == 0) {
      return const EpisodeEmptyNote(
        message: 'No practice questions for this lesson yet.',
      );
    }
    final summary =
        '$questionCount Question${questionCount == 1 ? '' : 's'} on This Lesson';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoNoteCard(
          icon: unlocked ? LucideIcons.listChecks : LucideIcons.lock,
          tone: unlocked ? palette.rose : palette.slate,
          message: summary,
        ),
        const SizedBox(height: 14),
        Text(
          unlocked
              ? 'You finished this lesson. Try the questions now.'
              : 'Finish watching to unlock the questions.',
          style: AppFonts.regular(
            color: palette.textMuted,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        if (unlocked) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.brand,
                foregroundColor: palette.card,
                shape: const StadiumBorder(),
                textStyle: AppFonts.bold(fontSize: 16),
              ),
              onPressed: onStart,
              child: const Text('Start Practice'),
            ),
          ),
        ],
      ],
    );
  }
}
