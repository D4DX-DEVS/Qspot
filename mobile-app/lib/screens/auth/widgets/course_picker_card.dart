import 'package:flutter/material.dart';

import '../../../services/course_service.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/auth_theme.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import 'course_rows_placeholder.dart';

/// Multi-select course list. Shows placeholder rows under the section title
/// while [isLoading] and nothing at all when there are no courses.
class CoursePickerCard extends StatelessWidget {
  const CoursePickerCard({
    super.key,
    required this.courses,
    required this.selectedIds,
    required this.onToggle,
    this.isLoading = false,
  });

  final List<CourseModel> courses;
  final Set<String> selectedIds;
  final void Function(String courseId, bool selected) onToggle;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty && !isLoading) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Courses',
          style: AppFonts.semiBold(color: colors.onSurface, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text(
          'You can choose more than one and change this later.',
          style: AppFonts.regular(
            color: colors.onSurfaceVariant,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const CourseRowsPlaceholder()
        else
          // The list usually arrives after the form has settled, so it eases
          // in by itself.
          StaggeredEntrance(rise: 12, child: _list(colors)),
      ],
    );
  }

  Widget _list(ColorScheme colors) {
    return Material(
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AuthTheme.fieldRadius),
        side: BorderSide(color: colors.outline),
      ),
      child: Column(
        children: [
          for (var i = 0; i < courses.length; i++) ...[
            PressableScale(
              pressedScale: 0.98,
              child: CheckboxListTile(
                value: selectedIds.contains(courses[i].id),
                onChanged: (selected) =>
                    onToggle(courses[i].id, selected ?? false),
                title: Text(courses[i].title),
                subtitle: courses[i].subtitle.isEmpty
                    ? null
                    : Text(courses[i].subtitle),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
            if (i < courses.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}
