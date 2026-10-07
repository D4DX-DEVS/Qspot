import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:printing/printing.dart';

import '../../../utils/widget_capture.dart';
import '../model/certificate_model.dart';
import '../service/certificate_pdf_service.dart';

/// Opens the platform share sheet for a PDF. Matches [Printing.sharePdf].
typedef PdfSharer =
    Future<bool> Function(Uint8List bytes, String filename, Rect? bounds);

Future<bool> _sharePdf(Uint8List bytes, String filename, Rect? bounds) =>
    Printing.sharePdf(bytes: bytes, filename: filename, bounds: bounds);

/// Turns the on-screen certificate into a PDF and shares it.
class CertificateShareProvider extends ChangeNotifier {
  CertificateShareProvider(this.certificate, {PdfSharer? sharer})
    : _sharer = sharer ?? _sharePdf;

  final CertificateModel certificate;
  final PdfSharer _sharer;

  /// Put on the certificate's [RepaintBoundary]; the PDF is drawn from it.
  final GlobalKey sheetKey = GlobalKey();

  /// A4 at about 216 dpi: sharp in print, a few hundred KB.
  static const double capturePixelRatio = 3;

  bool _sharing = false;
  bool _disposed = false;

  bool get isSharing => _sharing;

  /// Builds and shares the PDF. Returns a message to show the student when
  /// it fails, or null when the share sheet opened.
  Future<String?> share() async {
    if (_sharing) return null;
    _setSharing(true);
    try {
      final png = await WidgetCapture.png(
        sheetKey,
        pixelRatio: capturePixelRatio,
      );
      final pdf = await CertificatePdfService.fromImage(
        png,
        title: '${certificate.title} - ${certificate.examTitle}',
      );
      await _sharer(
        pdf,
        certificate.fileName,
        WidgetCapture.globalRect(sheetKey),
      );
      return null;
    } catch (e) {
      debugPrint('Certificate share failed: $e');
      return "We couldn't prepare your certificate. Please try again.";
    } finally {
      _setSharing(false);
    }
  }

  void _setSharing(bool value) {
    _sharing = value;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
