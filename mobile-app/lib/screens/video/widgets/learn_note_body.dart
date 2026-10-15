import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../model/video_model.dart';
import 'key_points_list.dart';

/// An episode's note text followed by its key points.
class LearnNoteBody extends StatelessWidget {
  const LearnNoteBody({super.key, required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final hasNote = video.learnText.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasNote)
          Text(
            video.learnText,
            style: AppFonts.regular(color: p.text, fontSize: 15, height: 1.55),
          ),
        if (video.learnPoints.isNotEmpty) ...[
          if (hasNote) const SizedBox(height: 20),
          KeyPointsList(points: video.learnPoints),
        ],
      ],
    );
  }
}
