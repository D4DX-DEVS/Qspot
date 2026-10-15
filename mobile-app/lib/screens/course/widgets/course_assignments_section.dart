import 'package:flutter/material.dart';

import '../../../widgets/common/section_header.dart';
import '../../assignment/model/assignment_model.dart';
import '../../assignment/widgets/assignment_tile.dart';

/// The course's assignments under the syllabus. Takes no room when the
/// course has none.
class CourseAssignmentsSection extends StatelessWidget {
  const CourseAssignmentsSection({
    super.key,
    required this.assignments,
    required this.onTap,
  });

  final List<AssignmentModel> assignments;
  final ValueChanged<AssignmentModel> onTap;

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const SectionHeader(title: 'Assignments'),
        const SizedBox(height: 8),
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
