import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../themes/home_palette.dart';
import '../model/certificate_model.dart';
import '../provider/certificate_share_provider.dart';
import 'certificate_sheet.dart';

/// [CertificateSheet] scaled to the largest size that fits the space it is
/// given, in any orientation, with pinch-to-zoom for reading small text.
///
/// The sheet sits in the [RepaintBoundary] of the [CertificateShareProvider]
/// above, so the shared PDF is drawn at full A4 size whatever the zoom.
class CertificatePreview extends StatelessWidget {
  const CertificatePreview({super.key, required this.certificate});

  final CertificateModel certificate;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final sheetKey = context.read<CertificateShareProvider>().sheetKey;
    return InteractiveViewer(
      maxScale: 4,
      child: Center(
        child: AspectRatio(
          aspectRatio: CertificateSheet.width / CertificateSheet.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: p.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: p.brand.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FittedBox(
              child: RepaintBoundary(
                key: sheetKey,
                child: CertificateSheet(certificate: certificate),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
