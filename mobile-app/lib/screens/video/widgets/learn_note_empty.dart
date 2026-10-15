import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../../widgets/common/surface_card.dart';

/// Shown in the quick-note popup when the episode has no note yet.
class LearnNoteEmpty extends StatelessWidget {
  const LearnNoteEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return SurfaceCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            SoftIconTile(
              icon: LucideIcons.lightbulb,
              tone: p.amber,
              size: 56,
              circle: true,
            ),
            const SizedBox(height: 12),
            Text(
              "This episode's quick note isn't ready yet.",
              textAlign: TextAlign.center,
              style: AppFonts.semiBold(color: p.text, fontSize: 14.5),
            ),
            const SizedBox(height: 6),
            Text(
              'The note written for this video will appear here.',
              textAlign: TextAlign.center,
              style: AppFonts.regular(
                color: p.textMuted,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
