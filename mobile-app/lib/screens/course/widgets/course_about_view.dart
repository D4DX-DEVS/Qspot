import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../services/course_service.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/surface_card.dart';

/// What the teacher wrote about the course in the admin panel: a description
/// and the things a learner will take away.
class CourseAboutView extends StatelessWidget {
  const CourseAboutView({super.key, required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final hasText = course.description.isNotEmpty || course.subtitle.isNotEmpty;
    if (!hasText && course.learnPoints.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No description has been added for this course yet.',
          textAlign: TextAlign.center,
          style: AppFonts.regular(color: palette.textMuted, fontSize: 14),
        ),
      );
    }
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (course.subtitle.isNotEmpty)
            Text(
              course.subtitle,
              style: AppFonts.bold(color: palette.text, fontSize: 16),
            ),
          if (course.description.isNotEmpty) ...[
            if (course.subtitle.isNotEmpty) const SizedBox(height: 8),
            Text(
              course.description,
              style: AppFonts.regular(
                color: palette.text,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
          if (course.learnPoints.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'What You Will Learn',
              style: AppFonts.bold(color: palette.text, fontSize: 15),
            ),
            const SizedBox(height: 10),
            for (final point in course.learnPoints)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.circleCheck,
                      size: 18,
                      color: palette.brand,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        point,
                        style: AppFonts.regular(
                          color: palette.text,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
