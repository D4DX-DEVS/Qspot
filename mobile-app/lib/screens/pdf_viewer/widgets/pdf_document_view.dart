import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import '../../../themes/home_palette.dart';
import '../../../widgets/common/state_message_view.dart';
import '../provider/pdf_viewer_provider.dart';
import 'pdf_loading_view.dart';

/// Scrollable, zoomable pages of the provider's PDF, with themed loading and
/// error states. Retrying swaps the document key so the file downloads again.
class PdfDocumentView extends StatelessWidget {
  const PdfDocumentView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewer = context.read<PdfViewerProvider>();
    final attempt = context.select<PdfViewerProvider, int>((v) => v.attempt);
    final p = HomePalette.of(context);
    return PdfViewer(
      PdfDocumentRefUri(
        Uri.parse(viewer.url),
        key: PdfDocumentRefKey(viewer.url, [attempt]),
      ),
      key: ValueKey(attempt),
      params: PdfViewerParams(
        backgroundColor: p.background,
        margin: 12,
        pageDropShadow: BoxShadow(
          color: Colors.black.withValues(alpha: p.isDark ? 0.5 : 0.12),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        onViewerReady: (document, controller) =>
            viewer.onViewerReady(document.pages.length, controller.pageNumber),
        onPageChanged: viewer.onPageChanged,
        loadingBannerBuilder: (_, bytesDownloaded, totalBytes) =>
            PdfLoadingView(
              progress: PdfViewerProvider.downloadProgress(
                bytesDownloaded,
                totalBytes,
              ),
            ),
        errorBannerBuilder: (_, _, _, _) => StateMessageView(
          icon: LucideIcons.fileX,
          title: 'Couldn’t open this PDF',
          message:
              'Check your connection and try again, or open it in another app.',
          onRetry: viewer.retry,
        ),
      ),
    );
  }
}
