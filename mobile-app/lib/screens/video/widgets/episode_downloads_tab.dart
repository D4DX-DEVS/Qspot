import 'package:flutter/material.dart';

import '../../../widgets/animation/staggered_entrance.dart';
import '../model/video_model.dart';
import 'episode_empty_note.dart';
import 'learning_material_card.dart';

/// Downloads tab of the episode details sheet: one card per handout.
class EpisodeDownloadsTab extends StatelessWidget {
  const EpisodeDownloadsTab({super.key, required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    final downloads = video.downloads;
    if (downloads.isEmpty) {
      return const EpisodeEmptyNote(
        message: 'No downloads for this episode yet.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: downloads.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = downloads[index];
        return StaggeredEntrance(
          index: index,
          child: LearningMaterialCard(material: item, showPreview: false),
        );
      },
    );
  }
}
