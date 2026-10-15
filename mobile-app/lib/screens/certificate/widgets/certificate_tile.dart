import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/common/tone_chip.dart';
import '../model/certificate_model.dart';

/// One certificate in the list: the exam it was for, when it was issued and
/// the mark. Tapping opens the certificate itself.
class CertificateTile extends StatelessWidget {
  const CertificateTile({
    super.key,
    required this.certificate,
    required this.onTap,
  });

  final CertificateModel certificate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final issued = certificate.issuedLabel;
    return Semantics(
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      label:
          '${certificate.examTitle}. ${certificate.title}. '
          '${issued.isEmpty ? '' : 'Issued $issued.'}',
      child: SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SoftIconTile(
              icon: LucideIcons.award,
              tone: palette.amber,
              size: 46,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    certificate.examTitle,
                    style: AppFonts.semiBold(color: palette.text, fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    issued.isEmpty ? certificate.title : 'Issued $issued',
                    style: AppFonts.regular(
                      color: palette.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ToneChip(
              label: certificate.isPractical
                  ? 'Practical'
                  : certificate.percentageLabel,
              tone: palette.mint,
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight, size: 20, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}
