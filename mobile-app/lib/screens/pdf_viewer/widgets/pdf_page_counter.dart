import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_fonts.dart';
import '../provider/pdf_viewer_provider.dart';

/// Floating "3 / 12" pill; hidden until the document has loaded. It ignores
/// touches so it never blocks scrolling the page underneath.
///
/// It floats over PDF pages, which stay white in both themes, so it is a
/// fixed dark scrim rather than a palette colour.
class PdfPageCounter extends StatelessWidget {
  const PdfPageCounter({super.key});

  @override
  Widget build(BuildContext context) {
    final label = context.select<PdfViewerProvider, String?>(
      (viewer) => viewer.pageLabel,
    );
    if (label == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            label,
            style: AppFonts.semiBold(color: Colors.white, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
