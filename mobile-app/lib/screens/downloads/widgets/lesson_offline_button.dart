import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../utils/byte_size.dart';
import '../../video/model/video_model.dart';
import '../model/lesson_download_plan.dart';
import '../provider/downloads_provider.dart';

/// On a lesson: save it for offline, see the progress, or remove the saved
/// copy. Hidden when the lesson has nothing that can be saved.
class LessonOfflineButton extends StatelessWidget {
  const LessonOfflineButton({super.key, required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadsProvider?>();
    // The web app can't keep files; it always streams.
    if (kIsWeb ||
        downloads == null ||
        LessonDownloadPlan.filesFor(video).isEmpty) {
      return const SizedBox.shrink();
    }
    final p = HomePalette.of(context);
    final id = video.id;
    final saved = downloads.lessonFor(id);
    final error = downloads.errorFor(id);

    Widget body;
    if (downloads.isSaving(id)) {
      body = Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saving for offline…',
                  style: AppFonts.semiBold(color: p.text, fontSize: 13),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: downloads.progressFor(id),
                  color: p.brand,
                  backgroundColor: p.cardBorder,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => downloads.cancel(id),
            child: const Text('Cancel'),
          ),
        ],
      );
    } else if (saved != null) {
      body = Row(
        children: [
          Icon(LucideIcons.circleCheck, color: p.mint.color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Saved on this phone · ${byteSize(saved.bytes)}',
              style: AppFonts.semiBold(color: p.text, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => downloads.remove(id),
            child: const Text('Remove'),
          ),
        ],
      );
    } else {
      body = SizedBox(
        height: 46,
        child: OutlinedButton.icon(
          onPressed: () => downloads.save(video),
          icon: const Icon(LucideIcons.download),
          label: Text(
            LessonDownloadPlan.hasVideo(video)
                ? 'Save for offline'
                : 'Save handouts for offline',
            style: AppFonts.bold(fontSize: 14),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: p.brand,
            side: BorderSide(color: p.brand, width: 1.5),
            shape: const StadiumBorder(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error, style: AppFonts.regular(color: p.error, fontSize: 12.5)),
        ],
      ],
    );
  }
}
