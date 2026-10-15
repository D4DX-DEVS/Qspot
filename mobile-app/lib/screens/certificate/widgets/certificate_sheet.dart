import 'package:flutter/material.dart';

import '../model/certificate_model.dart';

/// The printable certificate, laid out at a fixed A4 landscape size in
/// points so the shared PDF matches the admin panel's printed copy
/// (Qspot-admin/src/utils/certificateHtml.js, scaled by 0.75).
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

  static const Color _paper = Color(0xFFF7F1EB);
  static const Color _brand = Color(0xFF701845);
  static const Color _gold = Color(0xFFE0AE73);
  static const Color _ink = Color(0xFF111827);
  static const Color _body = Color(0xFF4B4350);
  static const Color _meta = Color(0xFF5C5360);
  static const Color _muted = Color(0xFF6B6270);

  static TextStyle _serif(double size, Color color, {FontWeight? weight}) =>
      TextStyle(
        fontFamily: 'Georgia',
        fontFamilyFallback: const ['serif'],
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: 1.3,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: _paper,
      padding: const EdgeInsets.all(51),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: _brand, width: 2.25),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFAF6), Color(0xFFF8E9EE)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: _gold, width: 0.75),
                  ),
                ),
              ),
            ),
            Positioned.fill(child: _content()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 34,
              child: Text(
                'Certificate No. ${certificate.certificateNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: _muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 34, 34, 50),
      // Admin text fields allow up to 500 characters; shrink the whole block
      // rather than overflow the page when they are long.
      child: LayoutBuilder(
        builder: (context, constraints) => FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(width: constraints.maxWidth, child: _lines()),
        ),
      ),
    );
  }

  Widget _lines() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          certificate.issuerName.toUpperCase(),
          textAlign: TextAlign.center,
          style: _serif(9, _brand).copyWith(letterSpacing: 3.15),
        ),
        const SizedBox(height: 10.5),
        Text(
          certificate.title,
          textAlign: TextAlign.center,
          style: _serif(28.5, _brand, weight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'This certificate is proudly presented to',
          textAlign: TextAlign.center,
          style: _serif(12, _ink),
        ),
        const SizedBox(height: 9),
        Text(
          certificate.studentName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _serif(31.5, _ink, weight: FontWeight.bold),
        ),
        const SizedBox(height: 9),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 465),
          child: Text.rich(
            TextSpan(
              text: '${certificate.description}\n',
              children: [
                TextSpan(
                  text: certificate.examTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: _serif(13.5, _body).copyWith(height: 1.5),
          ),
        ),
        const SizedBox(height: 21),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _metaItem('Score', certificate.percentageLabel),
            if (certificate.issuedLabel.isNotEmpty) ...[
              const SizedBox(width: 52),
              _metaItem('Issued', certificate.issuedLabel),
            ],
          ],
        ),
        const SizedBox(height: 21),
        Container(
          constraints: const BoxConstraints(minWidth: 135),
          padding: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _brand, width: 0.75)),
          ),
          child: Text(
            certificate.signatoryName,
            textAlign: TextAlign.center,
            style: _serif(10.5, _ink),
          ),
        ),
      ],
    );
  }

  Widget _metaItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: _serif(10.5, _meta)),
        Text(value, style: _serif(10.5, _meta, weight: FontWeight.bold)),
      ],
    );
  }
}
