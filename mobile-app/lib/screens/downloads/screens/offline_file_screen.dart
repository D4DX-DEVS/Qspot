import 'dart:io';

import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../common/widgets/home_theme_scope.dart';

/// A saved image or text handout, shown without internet. (Saved PDFs open
/// in the PDF viewer.)
class OfflineFileScreen extends StatelessWidget {
  const OfflineFileScreen({
    super.key,
    required this.path,
    required this.title,
    required this.isImage,
  });

  final String path;
  final String title;
  final bool isImage;

  static Future<void> open(
    BuildContext context, {
    required String path,
    required String title,
    required bool isImage,
  }) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => HomeThemeScope(
        child: OfflineFileScreen(path: path, title: title, isImage: isImage),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return Scaffold(
      appBar: CommonAppBar(title: title),
      body: isImage
          ? InteractiveViewer(
              maxScale: 5,
              child: Center(child: Image.file(File(path))),
            )
          : FutureBuilder<String>(
              future: File(path).readAsString(),
              builder: (context, snapshot) => SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.contentInset),
                child: Text(
                  snapshot.data ?? '',
                  style: AppFonts.regular(color: p.text, height: 1.5),
                ),
              ),
            ),
    );
  }
}
