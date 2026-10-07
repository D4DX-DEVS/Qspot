import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../../widgets/common/surface_card.dart';
import '../model/video_model.dart';

/// Shared Learn/Downloads attachment card; images preview inside Learn.
class LearningMaterialCard extends StatelessWidget {
  const LearningMaterialCard({
    super.key,
    required this.material,
    this.showPreview = true,
  });

  final VideoDownload material;
  final bool showPreview;

  Future<void> _open(BuildContext context) async {
    try {
      final uri = Uri.parse(material.resolvedUrl);
      if (!const {'http', 'https'}.contains(uri.scheme) || uri.host.isEmpty) {
        throw const FormatException('Invalid material URL');
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showPreview && material.isImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 1.6,
                child: Image(
                  image: ResizeImage(
                    NetworkImage(material.resolvedUrl),
                    width: 640,
                    height: 640,
                    policy: ResizeImagePolicy.fit,
                  ),
                  fit: BoxFit.contain,
                  semanticLabel: material.title,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, _, _) => Center(
                    child: Text(
                      'Preview unavailable. Tap to open the image.',
                      textAlign: TextAlign.center,
                      style: AppFonts.regular(color: p.textMuted, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              SoftIconTile(
                icon: material.isImage
                    ? LucideIcons.image
                    : material.isText
                    ? LucideIcons.fileText
                    : LucideIcons.file,
                tone: p.rose,
                size: 42,
              ),
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
              Icon(LucideIcons.externalLink, size: 18, color: p.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}
