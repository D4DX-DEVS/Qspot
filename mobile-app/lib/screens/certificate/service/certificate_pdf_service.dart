import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds the shareable certificate PDF.
///
/// The page is an image of the on-screen certificate rather than PDF text:
/// the `pdf` package cannot shape Malayalam, so a Malayalam name would print
/// as broken glyphs. Flutter's text engine shapes it correctly, and the PDF
/// then matches the preview exactly.
class CertificatePdfService {
  CertificatePdfService._();

  /// One A4 landscape page filled edge to edge with [png], which should
  /// already have A4 landscape proportions.
  static Future<Uint8List> fromImage(Uint8List png, {required String title}) {
    final format = PdfPageFormat.a4.landscape;
    final image = pw.MemoryImage(png);
    final doc = pw.Document(title: title, creator: 'QSPOT', author: 'QSPOT')
      ..addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.SizedBox(
            width: format.width,
            height: format.height,
            child: pw.Image(image, fit: pw.BoxFit.fill),
          ),
        ),
      );
    return doc.save();
  }
}
