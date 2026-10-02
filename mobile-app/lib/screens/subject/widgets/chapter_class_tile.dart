import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/surface_card.dart';
import '../model/chapter_progress.dart';
import 'chapter_progress_line.dart';
import 'chapter_status_chip.dart';
import 'chapter_thumbnail.dart';

/// One chapter as a row in a class syllabus: cover with its number, "Chapter
/// 3" and a status pill, the name, then lesson progress. It is as tall as its
/// text needs, so long names are always shown in full.
class ChapterClassTile extends StatelessWidget {
  const ChapterClassTile({
    super.key,
    required this.number,
    required this.title,
    required this.progress,
    required this.onTap,
    this.imageUrl,
  });

  final int number;
  final String title;
  final String? imageUrl;
  final ChapterProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Semantics(
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      label: progress.total > 0
          ? 'Open chapter $number, $title, ${progress.completed} of '
                '${progress.total} lessons complete'
          : 'Open chapter $number, $title',
      child: SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        color: palette.card,
        borderColor: palette.cardBorder,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChapterThumbnail(number: number, imageUrl: imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Chapter $number',
                          style: AppFonts.semiBold(
                            color: palette.brand,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      ChapterStatusChip(status: progress.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: AppFonts.bold(
                      color: palette.text,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ChapterProgressLine(progress: progress),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
