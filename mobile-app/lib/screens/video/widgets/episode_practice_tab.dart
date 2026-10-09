import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/info_note_card.dart';
import '../../../widgets/common/loading_skeleton.dart';
import '../model/video_model.dart';
import '../provider/video_details_sheet_provider.dart';
import '../provider/video_provider.dart';
import '../screens/video_questions_screen.dart';
import 'episode_empty_note.dart';

/// Practice tab of the episode details sheet: question count, a lock note
/// until the episode is finished, then a start button.
class EpisodePracticeTab extends StatelessWidget {
  const EpisodePracticeTab({super.key, required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final details = context.watch<VideoDetailsSheetProvider>();
    if (details.loadingQuestions) return const LoadingSkeleton();
    final count = details.questions.length;
    if (count == 0) {
      return const EpisodeEmptyNote(
        message: 'No practice questions for this episode yet.',
      );
    }
    final unlocked =
        context.watch<VideoProvider>().progressFor(video.id)?.completed == true;
    final summary = '$count Question${count == 1 ? '' : 's'} on This Episode';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StaggeredEntrance(
            child: InfoNoteCard(
              icon: unlocked ? LucideIcons.listChecks : LucideIcons.lock,
              tone: unlocked ? p.rose : p.slate,
              message: summary,
            ),
          ),
          const SizedBox(height: 16),
          StaggeredEntrance(
            index: 1,
            child: Text(
              unlocked
                  ? 'You finished this episode — try the questions below.'
                  : 'Finish watching to unlock the quiz.',
              style: AppFonts.regular(
                color: p.textMuted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
          const Spacer(),
          if (unlocked)
            StaggeredEntrance(
              index: 2,
              child: PressableScale(
                haptic: true,
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.brand,
                      foregroundColor: p.card,
                      shape: const StadiumBorder(),
                      textStyle: AppFonts.bold(fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      VideoQuestionsScreen.open(context, video);
                    },
                    child: const Text('Start Practice'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
