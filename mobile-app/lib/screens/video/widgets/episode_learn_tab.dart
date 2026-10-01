import 'package:flutter/material.dart';

import '../model/video_model.dart';
import 'episode_empty_note.dart';
import 'learn_note_body.dart';

/// Learn tab of the episode details sheet: the note and its key points.
class EpisodeLearnTab extends StatelessWidget {
  const EpisodeLearnTab({super.key, required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    if (video.learnText.isEmpty && video.learnPoints.isEmpty) {
      return const EpisodeEmptyNote(message: 'No notes for this episode yet.');
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [LearnNoteBody(video: video)],
    );
  }
}
