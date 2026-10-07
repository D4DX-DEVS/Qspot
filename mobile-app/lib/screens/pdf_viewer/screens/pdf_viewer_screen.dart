import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/common/common_app_bar.dart';
import '../../common/widgets/home_theme_scope.dart';
import '../provider/pdf_viewer_provider.dart';
import '../widgets/pdf_document_view.dart';
import '../widgets/pdf_open_externally_action.dart';
import '../widgets/pdf_page_counter.dart';

/// Full-screen in-app reader for a PDF at [url].
class PdfViewerScreen extends StatelessWidget {
  const PdfViewerScreen({super.key, required this.url, required this.title});

  final String url;
  final String title;

  static Future<void> open(
    BuildContext context, {
    required String url,
    required String title,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HomeThemeScope(
          child: PdfViewerScreen(url: url, title: title),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PdfViewerProvider(url: url),
      child: Scaffold(
        appBar: CommonAppBar(
          title: title,
          actions: const [PdfOpenExternallyAction(), SizedBox(width: 16)],
        ),
        body: const Stack(
          children: [
            Positioned.fill(child: PdfDocumentView()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: Center(child: PdfPageCounter()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
