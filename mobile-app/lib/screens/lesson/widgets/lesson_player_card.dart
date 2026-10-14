import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/animated_progress_bar.dart';

/// The lesson's picture with a play button. Tapping it plays the lesson, or
/// shows why it is closed. A bar along the bottom shows how far the learner
/// has watched.
class LessonPlayerCard extends StatelessWidget {
  const LessonPlayerCard({
    super.key,
    required this.thumbnailUrl,
    required this.label,
    required this.fraction,
    required this.enabled,
    required this.onTap,
  });

  final String thumbnailUrl;

  /// What tapping does, e.g. "Resume at 6:20", or why the lesson is closed.
  final String label;

  /// 0 to 1, how far the learner has watched.
  final double fraction;

  /// False while the lesson is locked or not released.
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final fallback = ColoredBox(
      color: palette.brandSoft,
      child: Icon(LucideIcons.clapperboard, size: 40, color: palette.textMuted),
    );
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(
            color: palette.brandSoft,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  thumbnailUrl.isEmpty
                      ? fallback
                      : CachedNetworkImage(
                          imageUrl: thumbnailUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => fallback,
                        ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: enabled ? 0.0 : 0.35),
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.5),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        enabled ? LucideIcons.play : LucideIcons.lock,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.semiBold(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (fraction > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AnimatedProgressBar(
                        value: fraction,
                        minHeight: 5,
                        color: palette.brand,
                        backgroundColor: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
