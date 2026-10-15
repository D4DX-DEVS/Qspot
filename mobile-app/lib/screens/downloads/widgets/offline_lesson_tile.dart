import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../utils/byte_size.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../../widgets/common/surface_card.dart';
import '../model/offline_lesson.dart';

/// A saved lesson in the Downloads list: what is saved, its size, Remove.
class OfflineLessonTile extends StatelessWidget {
  const OfflineLessonTile({
    super.key,
    required this.lesson,
    required this.onRemove,
    this.onTap,
  });

  final OfflineLesson lesson;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      child: Row(
        children: [
          SoftIconTile(
            icon: lesson.hasVideo
                ? LucideIcons.circlePlay
                : LucideIcons.fileText,
            tone: p.teal,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.bold(color: p.text, fontSize: 14.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '${lesson.contentsLabel} · ${byteSize(lesson.bytes)}',
                  style: AppFonts.regular(color: p.textMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove ${lesson.title}',
            onPressed: onRemove,
            icon: Icon(LucideIcons.trash2, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}
