import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import 'chapter_number_badge.dart';

/// Small portrait cover for a chapter with its number pinned in the corner.
/// Without a picture (or while it loads or fails) the number sits on a soft
/// brand tile instead.
class ChapterThumbnail extends StatelessWidget {
  const ChapterThumbnail({
    super.key,
    required this.number,
    this.imageUrl,
    this.width = 64,
  });

  final int number;
  final String? imageUrl;
  final double width;

  /// Same shape as the chapter artwork (3 wide to 4 tall).
  static const double _aspectRatio = 3 / 4;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final url = imageUrl;
    final fallback = ColoredBox(
      color: palette.brandSoft,
      child: Center(
        child: Text(
          '$number',
          style: AppFonts.extraBold(color: palette.brand, fontSize: 24),
        ),
      ),
    );

    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url == null)
                  fallback
                else
                  CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => fallback,
                    errorWidget: (_, __, ___) => fallback,
                  ),
                if (url != null)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: ChapterNumberBadge(number: number),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
