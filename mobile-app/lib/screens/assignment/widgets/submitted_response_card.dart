import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/surface_card.dart';
import '../model/assignment_model.dart';

/// What the learner sent for an assignment: their written answer and the
/// files they attached, either of which may be missing.
class SubmittedResponseCard extends StatelessWidget {
  const SubmittedResponseCard({
    super.key,
    required this.text,
    this.files = const [],
  });

  final String text;
  final List<AssignmentFileModel> files;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (text.isNotEmpty)
            Text(
              text,
              style: AppFonts.regular(
                color: palette.text,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          if (text.isNotEmpty && files.isNotEmpty) const SizedBox(height: 8),
          for (final file in files)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                file.mimeType.startsWith('audio')
                    ? LucideIcons.music
                    : LucideIcons.image,
                color: palette.brand,
              ),
              title: Text(
                file.name,
                style: AppFonts.medium(color: palette.text),
              ),
              subtitle: Text(
                file.mimeType,
                style: AppFonts.regular(color: palette.textMuted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
