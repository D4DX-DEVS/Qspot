import 'package:flutter/material.dart';

import '../model/certificate_model.dart';

/// The printable certificate, laid out at a fixed A4 landscape size in
/// points: the design (EXAM CERTIFICATE_QSPOT.pdf) as one picture, the
/// student's name on its line and the certificate number and issue date
/// small at the foot. It matches the admin panel's printed copy
/// (Qspot-admin/src/utils/certificateHtml.js) and the web app's
/// (webapp/src/features/certificate/models/certificateLayout.js); keep the
/// positions below the same as theirs.
///
/// The colours are the paper's, not the app theme's: the certificate is a
/// document and must look the same in light and dark mode and in print.
/// Scale it on screen with a [FittedBox]; capture it through a
/// [RepaintBoundary] directly around this widget.
class CertificateSheet extends StatelessWidget {
  const CertificateSheet({super.key, required this.certificate});

  final CertificateModel certificate;

  static const double width = 842;
  static const double height = 595;

  static const String _template = 'assets/images/certificate_participation.jpg';

  // The blank line runs x 336.8..789.4 at y 300.5; the name stands centred
  // on it, its last line 6pt above it (bottom measured from the page foot).
  static const double _nameLeft = 336.8;
  static const double _nameWidth = 452.6;
  static const double _nameBottom = 301;
  // Room for two lines of a long (smaller) name before it shrinks further,
  // clear of "This is to certify that" above.
  static const double _nameMaxHeight = 44;

  static const double _detailsLeft = 336.8;
  static const double _detailsBottom = 20;

  static const Color _muted = Color(0xFF6B6270);

  @override
  Widget build(BuildContext context) {
    final details = TextStyle(
      fontFamily: 'Manrope',
      fontSize: 7.5,
      color: _muted,
    );
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _template,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
          ),
          Positioned(
            left: _nameLeft,
            width: _nameWidth,
            bottom: _nameBottom,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: _nameMaxHeight),
              // Long names are set smaller; a very long one wraps to a
              // second line, then shrinks to fit.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: _nameWidth,
                  child: Text(
                    certificate.studentName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: certificate.nameFontSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: _detailsLeft,
            bottom: _detailsBottom,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Certificate No. ${certificate.certificateNumber}',
                  style: details,
                ),
                if (certificate.issuedLabel.isNotEmpty)
                  Text(' · Issued ${certificate.issuedLabel}', style: details),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
