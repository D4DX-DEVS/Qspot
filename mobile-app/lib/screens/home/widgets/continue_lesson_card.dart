import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../widgets/common/surface_card.dart';

/// Compact lesson card for "pick up where you left off": thumbnail, subject,
/// title, a progress bar and a short status line.
class ContinueLessonCard extends StatelessWidget {
  const ContinueLessonCard({
    super.key,
    required this.title,
    required this.subject,
    required this.thumbnailUrl,
    required this.progress,
    required this.status,
    required this.onTap,
    this.width = 220,
  });

  final String title;
  final String subject;
  final String thumbnailUrl;

  /// 0..1 watched.
  final double progress;
  final String status;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
      color: scheme.primaryContainer,
      child: Icon(Icons.play_lesson_outlined, color: scheme.primary),
    );
    return SizedBox(
      width: width,
      child: SurfaceCard(
        onTap: onTap,
        radius: 16,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox.square(
                dimension: 72,
                child: thumbnailUrl.isEmpty
                    ? fallback
                    : CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => fallback,
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.regular(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.semiBold(
                      color: scheme.onSurface,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 4,
                      color: scheme.secondary,
                      backgroundColor: scheme.primaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: AppFonts.regular(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
