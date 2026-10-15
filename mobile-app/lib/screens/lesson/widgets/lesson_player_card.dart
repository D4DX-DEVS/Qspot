import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/animated_progress_bar.dart';

/// The lesson's picture, edge to edge, with a play button in the middle and,
/// along the bottom, how far the learner has watched: the time reached, a
/// bar, and the length. Tapping it plays the lesson. While the lesson is
/// closed, the bottom says why instead.
class LessonPlayerCard extends StatelessWidget {
  const LessonPlayerCard({
    super.key,
    required this.thumbnailUrl,
    required this.label,
    required this.fraction,
    required this.enabled,
    required this.onTap,
    this.positionText,
    this.durationText,
  });

  /// The dark behind the picture, and what shows when there is none.
  static const _backdrop = Color(0xFF2B1A22);

  final String thumbnailUrl;

  /// What tapping does, e.g. "Resume at 6:20", or why the lesson is closed.
  /// Read out by screen readers.
  final String label;

  /// 0 to 1, how far the learner has watched.
  final double fraction;

  /// False while the lesson is not released.
  final bool enabled;
  final VoidCallback onTap;

  /// Time reached and total length, e.g. "6:20" and "14:00". The row along
  /// the bottom is left out when the length is not known.
  final String? positionText;
  final String? durationText;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final showTimes = positionText != null && durationText != null;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Material(
          color: _backdrop,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (thumbnailUrl.isNotEmpty)
                  Opacity(
                    opacity: enabled ? 0.75 : 0.4,
                    child: CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                    child: Icon(
                      enabled ? Icons.play_arrow_rounded : LucideIcons.lock,
                      color: palette.brand,
                      size: enabled ? 34 : 24,
                    ),
                  ),
                ),
                if (!enabled)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppFonts.semiBold(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  )
                else if (showTimes)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Row(
                      children: [
                        _time(positionText!),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AnimatedProgressBar(
                            value: fraction,
                            minHeight: 4,
                            color: Colors.white,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _time(durationText!),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _time(String text) =>
      Text(text, style: AppFonts.semiBold(color: Colors.white, fontSize: 11.5));
}
