import 'package:flutter/material.dart';

import '../../video/model/video_model.dart';
import '../../video/widgets/episode_empty_note.dart';
import '../../video/widgets/learn_note_body.dart';

/// The lesson's note and key points, as written in the admin panel.
class LessonLearnPanel extends StatelessWidget {
  const LessonLearnPanel({super.key, required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    if (!video.hasLearnContent) {
      return const EpisodeEmptyNote(message: 'No notes for this lesson yet.');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LearnNoteBody(video: video),
    );
  }
}
