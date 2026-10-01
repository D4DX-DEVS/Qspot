import 'package:flutter/material.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../model/video_model.dart';

/// Episode title with its subject and date underneath, in white for use over
/// the video stage. The caller decides where it sits: bottom-left in portrait,
/// beside the back button in landscape.
class VideoTitleBlock extends StatelessWidget {
  const VideoTitleBlock({
    super.key,
    required this.video,
    this.titleMaxLines = 2,
  });

  final VideoModel video;
  final int titleMaxLines;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if ((video.subjectName ?? '').isNotEmpty) video.subjectName!,
      if (video.formattedDate.isNotEmpty) video.formattedDate,
    ].join('  ·  ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          video.displayTitle,
          maxLines: titleMaxLines,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.bold(
            color: AppColors.white,
            fontSize: 17,
            height: 1.3,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.regular(color: AppColors.white70, fontSize: 12.5),
          ),
        ],
      ],
    );
  }
}
