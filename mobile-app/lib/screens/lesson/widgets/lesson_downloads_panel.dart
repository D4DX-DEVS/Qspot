import 'package:flutter/material.dart';

import '../../video/model/video_model.dart';
import '../../video/widgets/episode_empty_note.dart';
import '../../video/widgets/learning_material_card.dart';

/// One card per handout attached to the lesson.
class LessonDownloadsPanel extends StatelessWidget {
  const LessonDownloadsPanel({super.key, required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    if (video.downloads.isEmpty) {
      return const EpisodeEmptyNote(
        message: 'No downloads for this lesson yet.',
      );
    }
    return Column(
      children: [
        for (final material in video.downloads)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LearningMaterialCard(material: material),
          ),
      ],
    );
  }
}
