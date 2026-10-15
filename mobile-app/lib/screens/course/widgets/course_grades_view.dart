import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../grades/model/grade_entry.dart';
import '../../grades/widgets/grade_tile.dart';

/// The learner's marks for this course, newest first.
class CourseGradesView extends StatelessWidget {
  const CourseGradesView({
    super.key,
    required this.entries,
    this.loading = false,
  });

  final List<GradeEntry> entries;

  /// Marks are still being fetched.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          loading
              ? 'Loading your grades...'
              : 'No grades for this course yet. Quiz, practice and '
                    'assignment marks will show up here.',
          textAlign: TextAlign.center,
          style: AppFonts.regular(
            color: palette.textMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GradeTile(entry: entry),
          ),
      ],
    );
  }
}
