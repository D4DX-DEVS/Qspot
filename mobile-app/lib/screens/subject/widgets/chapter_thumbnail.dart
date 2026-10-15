import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import 'chapter_number_badge.dart';

/// Compact chapter artwork with its number pinned in the corner.
/// Without a picture (or while it loads or fails) a branded book tile appears.
class ChapterThumbnail extends StatelessWidget {
  const ChapterThumbnail({
    super.key,
    required this.number,
    this.imageUrl,
    this.width = 96,
  });

  final int number;
  final String? imageUrl;
  final double width;

  /// Chapter artwork is served as a 640x400 (16:10) image. Keeping that
  /// ratio here prevents the title baked into the artwork from being cropped.
  static const double _aspectRatio = 16 / 10;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final url = imageUrl != null && imageUrl!.isNotEmpty ? imageUrl : null;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.brandSoft, palette.brandSoft.withValues(alpha: 0.6)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(LucideIcons.bookOpen, size: 30, color: palette.brand),
          Padding(
            padding: const EdgeInsets.only(top: 34),
            child: Text(
              '$number',
              textAlign: TextAlign.center,
              style: AppFonts.extraBold(color: palette.brand, fontSize: 18),
            ),
          ),
        ],
      ),
    );

    final imageScrim = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.22)],
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
                    // Preserve the complete dynamic thumbnail artwork. Cover
                    // can crop baked chapter titles on narrow cards; contain
                    // keeps them centred and readable at every width.
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    color: palette.slate.soft,
                    colorBlendMode: BlendMode.dstOver,
                    placeholder: (_, __) => fallback,
                    errorWidget: (_, __, ___) => fallback,
                  ),
                if (url != null) Positioned.fill(child: imageScrim),
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
