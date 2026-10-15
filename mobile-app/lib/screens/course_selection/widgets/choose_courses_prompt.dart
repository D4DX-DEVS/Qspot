import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../../widgets/common/surface_card.dart';
import 'course_selection_sheet.dart';

/// Card shown in place of lessons when a learner has not chosen any course:
/// explains why the app is empty and opens the course picker.
class ChooseCoursesPrompt extends StatelessWidget {
  const ChooseCoursesPrompt({super.key, this.onSaved});

  /// Called after the learner saves their courses, so the caller can reload.
  final VoidCallback? onSaved;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SoftIconTile(
            icon: LucideIcons.graduationCap,
            tone: palette.rose,
            size: 64,
            circle: true,
          ),
          const SizedBox(height: 14),
          Text(
            'Choose Your Courses',
            textAlign: TextAlign.center,
            style: AppFonts.bold(color: palette.text, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick the courses you are taking and your lessons will appear here.',
            textAlign: TextAlign.center,
            style: AppFonts.regular(
              color: palette.textMuted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.brand,
                foregroundColor: palette.card,
                minimumSize: const Size(0, 48),
              ),
              onPressed: () async {
                final saved = await CourseSelectionSheet.show(context);
                if (saved) onSaved?.call();
              },
              child: const Text('Choose Courses'),
            ),
          ),
        ],
      ),
    );
  }
}
