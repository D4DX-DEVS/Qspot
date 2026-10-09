import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/accent_tone.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/animation/animated_progress_bar.dart';
import '../../../widgets/common/surface_card.dart';
import '../model/continue_lesson_info.dart';

/// "Jump back in" lesson card: big thumbnail with a play button, the subject
/// on top and the progress along the bottom, then the title and an upbeat
/// status. [tone] colours the progress bar and status pill so a row of cards
/// feels varied.
class ContinueLessonCard extends StatelessWidget {
  const ContinueLessonCard({
    super.key,
    required this.title,
    required this.subject,
    required this.thumbnailUrl,
    required this.info,
    required this.tone,
    required this.onTap,
    this.width = 260,
  });

  final String title;
  final String subject;
  final String thumbnailUrl;
  final ContinueLessonInfo info;
  final AccentTone tone;
  final VoidCallback onTap;
  final double width;

  static const double _titleSize = 13.5;
  static const double _titleHeight = 1.25;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Semantics(
        button: true,
        label: '$title, $subject, ${info.label}',
        excludeSemantics: true,
        child: SurfaceCard(
          onTap: onTap,
          radius: 20,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _thumbnail(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: _details(context, scheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail() {
    final fallback = ColoredBox(
      color: tone.soft,
      child: Icon(LucideIcons.monitorPlay, color: tone.color, size: 36),
    );
    // Overlays sit on a photo, so they stay dark/white in both themes.
    return AspectRatio(
      aspectRatio: 16 / 9,
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
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x73000000)],
                stops: [0.45, 1],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.65),
                  width: 1.5,
                ),
              ),
              child: Icon(
                info.completed ? LucideIcons.rotateCcw : LucideIcons.play,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            top: 10,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subject,
                  style: AppFonts.semiBold(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedProgressBar(
              value: info.progress,
              minHeight: 5,
              color: tone.color,
              backgroundColor: Colors.white.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _details(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reserve two lines so every card in the row ends up the same height.
        // Text rounds each line up, so round the line before doubling it.
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                2 *
                MediaQuery.textScalerOf(
                  context,
                ).scale(_titleSize * _titleHeight).ceilToDouble(),
          ),
          child: Text(
            title,
            style: AppFonts.bold(
              color: scheme.onSurface,
              fontSize: _titleSize,
              height: _titleHeight,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tone.soft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${info.emoji} ${info.label}',
                style: AppFonts.semiBold(color: tone.color, fontSize: 11),
              ),
            ),
            if (info.timeLeft != null)
              Text(
                info.timeLeft!,
                style: AppFonts.medium(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
