import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../../widgets/common/surface_card.dart';
import '../model/video_model.dart';
import 'episode_empty_note.dart';

/// Downloads tab of the episode details sheet: one card per handout.
class EpisodeDownloadsTab extends StatelessWidget {
  const EpisodeDownloadsTab({super.key, required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
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
          child: SurfaceCard(
            radius: 16,
            padding: const EdgeInsets.all(14),
            onTap: () => launchUrl(
              Uri.parse(item.url),
              mode: LaunchMode.externalApplication,
            ),
            child: Row(
              children: [
                SoftIconTile(
                  icon: LucideIcons.download,
                  tone: p.rose,
                  size: 42,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.title,
                    style: AppFonts.semiBold(color: p.text, fontSize: 15),
                  ),
                ),
                Icon(LucideIcons.externalLink, size: 18, color: p.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }
}
