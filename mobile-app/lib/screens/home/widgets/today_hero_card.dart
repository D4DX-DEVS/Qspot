import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/banner_headline.dart';
import '../../../widgets/common/gold_pill_button.dart';
import '../../../widgets/common/gradient_card.dart';
import 'sparkle_accent.dart';

/// Burgundy "next step" card at the top of Today: optional eyebrow and
/// time estimate, title, description and a gold action pill, with an
/// optional lesson thumbnail beside the pill.
class TodayHeroCard extends StatelessWidget {
  const TodayHeroCard({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    this.actionIcon,
    this.eyebrow,
    this.meta,
    this.thumbnailUrl,
    this.showSparkle = false,
  });

  final String title;
  final String description;
  final String actionLabel;
  final IconData? actionIcon;
  final VoidCallback onAction;
  final String? eyebrow;

  /// Short note on the eyebrow line, e.g. "12 min".
  final String? meta;
  final String? thumbnailUrl;
  final bool showSparkle;

  @override
  Widget build(BuildContext context) {
    final thumb = thumbnailUrl;
    return GradientCard(
      minHeight: 178,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null || meta != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    eyebrow ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            ),
            const SizedBox(height: 10),
          ],
          BannerHeadline(
            title: title,
            subtitle: description,
            titleSize: 22,
            titleTrailing: showSparkle ? const SparkleAccent() : null,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Flexible(
                child: GoldPillButton(
                  label: actionLabel,
                  icon: actionIcon,
                  onPressed: onAction,
                ),
              ),
              if (thumb != null && thumb.isNotEmpty) ...[
                const Spacer(),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: thumb,
                    width: 68,
                    height: 50,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
