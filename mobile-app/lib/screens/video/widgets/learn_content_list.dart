import 'package:flutter/material.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../model/video_model.dart';
import 'learn_note_body.dart';
import 'learning_material_card.dart';

/// Builds image previews only when their cards approach the viewport.
class LearnContentList extends StatelessWidget {
  const LearnContentList({
    super.key,
    required this.video,
    this.padding = const EdgeInsets.all(20),
  });
  final VideoModel video;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final hasNotes = video.learnText.isNotEmpty || video.learnPoints.isNotEmpty;
    final headerCount =
        (hasNotes ? 1 : 0) + (video.downloads.isNotEmpty ? 1 : 0);
    return ListView.builder(
      padding: padding,
      itemCount: headerCount + video.downloads.length,
      itemBuilder: (context, index) {
        if (hasNotes && index == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: video.downloads.isEmpty ? 0 : 24),
            child: LearnNoteBody(video: video),
          );
        }
        if (index == headerCount - 1 && video.downloads.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Learning materials',
              style: AppFonts.bold(
                color: HomePalette.of(context).text,
                fontSize: 16,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LearningMaterialCard(
            material: video.downloads[index - headerCount],
          ),
        );
      },
    );
  }
}
