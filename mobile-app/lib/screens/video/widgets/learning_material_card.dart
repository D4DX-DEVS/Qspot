import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../widgets/common/surface_card.dart';
import '../../pdf_viewer/screens/pdf_viewer_screen.dart';
import '../model/video_model.dart';
import 'material_thumbnail.dart';

/// Downloads attachment card with a small preview of the file.
class LearningMaterialCard extends StatelessWidget {
  const LearningMaterialCard({super.key, required this.material});

  final VideoDownload material;

  Future<void> _open(BuildContext context) async {
    try {
      final uri = Uri.parse(material.resolvedUrl);
      if (!const {'http', 'https'}.contains(uri.scheme) || uri.host.isEmpty) {
        throw const FormatException('Invalid material URL');
      }
      if (material.isPdf) {
        await PdfViewerScreen.open(
          context,
          url: material.resolvedUrl,
          title: material.title,
        );
        return;
      }
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Keep URL/launcher details out of the student's error message.
    }
    if (!context.mounted) return;
    AppSnackBar.show(
      context,
      message:
          'We couldn’t open this file. Check your connection and try again.',
      color: AppColors.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final type = material.isImage
        ? 'Image'
        : material.isPdf
        ? 'PDF'
        : material.isText
        ? 'Text file'
        : 'File';
    return SurfaceCard(
      radius: 16,
      padding: const EdgeInsets.all(14),
      onTap: () => _open(context),
      child: Row(
        children: [
          MaterialThumbnail(material: material),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.title,
                  style: AppFonts.semiBold(color: p.text, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  '$type · Tap to open',
                  style: AppFonts.regular(color: p.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            material.isPdf
                ? LucideIcons.chevronRight
                : LucideIcons.externalLink,
            size: 18,
            color: p.textMuted,
          ),
        ],
      ),
    );
  }
}
