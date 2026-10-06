import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../../../widgets/animation/idle_attention.dart';
import '../../../widgets/common/banner_headline.dart';
import '../../../widgets/common/gold_pill_button.dart';
import '../../../widgets/common/gradient_card.dart';
import 'sparkle_accent.dart';

/// Burgundy "next step" card at the top of Today: optional eyebrow and
/// time estimate and title; the whole card is tappable, with an
/// optional lesson thumbnail as the card background.
class TodayHeroCard extends StatelessWidget {
  const TodayHeroCard({
    super.key,
    required this.title,
    required this.onAction,
    this.eyebrow,
    this.meta,
    this.thumbnailUrl,
    this.showSparkle = false,
    this.actionLabel = 'Start now',
  });

  final String title;
  final VoidCallback onAction;
  final String? eyebrow;

  /// Short note on the eyebrow line, e.g. "12 min".
  final String? meta;
  final String? thumbnailUrl;
  final bool showSparkle;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final thumb = thumbnailUrl;
    final hasThumb = thumb != null && thumb.isNotEmpty;
    final brand = HomePalette.of(context).brand;
    return PressableScale(
      // The nested CTA owns haptic feedback; keeping the card shell silent
      // avoids firing two selection pulses when the CTA is tapped.
      haptic: false,
      child: GestureDetector(
        // The CTA owns the accessible action. Keeping the decorative/card
        // tap out of the semantics tree prevents the full hero from being
        // announced and outlined as one giant button.
        excludeFromSemantics: true,
        onTap: onAction,
        child: GradientCard(
          backdrop: hasThumb
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                    ),
                    // Light at the top, deep at the bottom so the thumbnail
                    // stays visible and the text below stays readable.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0, 0.35, 1],
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                            brand.withValues(alpha: 0.95),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(
                            color: AppColors.white70,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.play,
                          color: AppColors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ],
                )
              : null,
          minHeight: hasThumb ? 240 : 178,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: SizedBox(
            height: hasThumb ? 240 - 42 : 178 - 42,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: hasThumb
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.center,
              children: [
                if (eyebrow != null || meta != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          eyebrow ?? '',
                          style: AppFonts.bold(
                            color: AppColors.white70,
                            fontSize: 11.5,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      if (meta != null)
                        Text(
                          meta!,
                          style: AppFonts.regular(
                            color: AppColors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
                if (!hasThumb) const SizedBox(height: 10),
                BannerHeadline(
                  title: title,
                  titleSize: 15,
                  titleTrailing: showSparkle ? const SparkleAccent() : null,
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IdleAttention(
                    child: GoldPillButton(
                      label: actionLabel,
                      icon: LucideIcons.play,
                      onPressed: onAction,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
