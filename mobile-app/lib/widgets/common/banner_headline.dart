import 'package:flutter/material.dart';

import '../../themes/app_colors.dart';
import '../../themes/app_fonts.dart';

/// White title and supporting line for content placed on a `GradientCard`.
/// [trailingWidth] keeps the text clear of the card's corner artwork.
class BannerHeadline extends StatelessWidget {
  const BannerHeadline({
    super.key,
    required this.title,
    this.subtitle,
    this.titleTrailing,
    this.trailingWidth = 0,
    this.titleSize = 21,
  });

  final String title;
  final String? subtitle;

  /// Small decoration after the title, e.g. sparkles.
  final Widget? titleTrailing;
  final double trailingWidth;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: trailingWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.bold(
                    color: AppColors.white,
                    fontSize: titleSize,
                    height: 1.2,
                  ),
                ),
              ),
              if (titleTrailing != null) ...[
                const SizedBox(width: 8),
                titleTrailing!,
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.regular(
                color: AppColors.white.withValues(alpha: 0.86),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
