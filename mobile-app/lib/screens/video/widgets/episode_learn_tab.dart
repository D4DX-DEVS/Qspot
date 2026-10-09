import 'package:flutter/material.dart';

import '../model/video_model.dart';
import 'episode_empty_note.dart';
import 'learn_content_list.dart';

/// Learn tab of the episode details sheet: the note and its key points.
class EpisodeLearnTab extends StatelessWidget {
  const EpisodeLearnTab({super.key, required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    if (!video.hasLearnContent) {
      return const EpisodeEmptyNote(message: 'No notes for this episode yet.');
    }
    return LearnContentList(video: video);
  }
}
