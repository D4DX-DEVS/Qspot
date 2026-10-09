import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/home_palette.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../model/video_model.dart';
import 'pdf_first_page_thumbnail.dart';
import 'text_snippet_thumbnail.dart';

/// Small square preview of a handout: the image itself, a PDF's first page
/// or a text file's opening lines. Falls back to the file-type icon while
/// loading, for other file types, or when the preview can't be shown.
class MaterialThumbnail extends StatelessWidget {
  const MaterialThumbnail({super.key, required this.material, this.size = 56});

  final VideoDownload material;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final url = material.resolvedUrl;
    final placeholder = SoftIconTile(
      icon: material.isImage
          ? LucideIcons.image
          : material.isText
          ? LucideIcons.fileText
          : LucideIcons.file,
      tone: p.rose,
      size: size,
    );
    if (url.isEmpty) return placeholder;

    final Widget preview;
    if (material.isImage) {
      // Decoded at twice the box so cover-cropping a wide image stays sharp.
      final pixels = (size * 2 * MediaQuery.devicePixelRatioOf(context))
          .round();
      preview = Image(
        image: ResizeImage(
          NetworkImage(url),
          width: pixels,
          height: pixels,
          policy: ResizeImagePolicy.fit,
        ),
        fit: BoxFit.cover,
        semanticLabel: material.title,
        frameBuilder: (_, child, frame, syncLoaded) =>
            frame == null && !syncLoaded ? placeholder : child,
        errorBuilder: (_, _, _) => placeholder,
      );
    } else if (material.isPdf) {
      preview = PdfFirstPageThumbnail(
        url: url,
        placeholder: placeholder,
        background: p.rose.soft,
      );
    } else if (material.isText) {
      preview = TextSnippetThumbnail(url: url, placeholder: placeholder);
    } else {
      return placeholder;
    }

    final radius = BorderRadius.circular(size * 0.3);
    return Container(
      width: size,
      height: size,
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: p.cardBorder),
      ),
      child: ClipRRect(borderRadius: radius, child: preview),
    );
  }
}
