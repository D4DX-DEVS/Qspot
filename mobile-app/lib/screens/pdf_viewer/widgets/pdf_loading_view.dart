import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';

/// Centered spinner shown while a PDF downloads; [progress] (0–1) turns it
/// into a determinate ring with a percentage once the file size is known.
class PdfLoadingView extends StatelessWidget {
  const PdfLoadingView({super.key, this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final percent = progress == null ? '' : ' ${(progress! * 100).round()}%';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(value: progress, color: p.brand),
          const SizedBox(height: 14),
          Text(
            'Opening PDF…$percent',
            style: AppFonts.medium(color: p.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
