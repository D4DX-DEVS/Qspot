import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// First page of the PDF at [url], fitted inside its box on [background].
/// Shows [placeholder] while the file loads or when it can't be opened.
class PdfFirstPageThumbnail extends StatelessWidget {
  const PdfFirstPageThumbnail({
    super.key,
    required this.url,
    required this.placeholder,
    required this.background,
  });

  final String url;
  final Widget placeholder;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return PdfDocumentViewBuilder.uri(
      Uri.parse(url),
      loadingBuilder: (_) => placeholder,
      errorBuilder: (_, _, _) => placeholder,
      builder: (context, document) {
        if (document == null || document.pages.isEmpty) return placeholder;
        return ColoredBox(
          color: background,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: PdfPageView(
              document: document,
              pageNumber: 1,
              decoration: const BoxDecoration(color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}
