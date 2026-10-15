import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../assignment/model/assignment_model.dart';
import '../../assignment/widgets/assignment_tile.dart';

/// The course's assignments, the content of the Assignments tab.
class CourseAssignmentsSection extends StatelessWidget {
  const CourseAssignmentsSection({
    super.key,
    required this.assignments,
    required this.onTap,
    this.loading = false,
  });

  final List<AssignmentModel> assignments;
  final ValueChanged<AssignmentModel> onTap;

  /// Assignments are still being fetched.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      final palette = HomePalette.of(context);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          loading
              ? 'Loading your assignments...'
              : 'No assignments for this course yet.',
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
        for (final assignment in assignments)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AssignmentTile(
              assignment: assignment,
              onTap: () => onTap(assignment),
            ),
          ),
      ],
    );
  }
}
