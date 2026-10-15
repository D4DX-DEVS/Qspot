import 'package:flutter/material.dart';

import '../../../widgets/common/underline_tab_bar.dart';
import '../model/course_tab.dart';

/// The sections of the course page: syllabus, assignments, grades, about.
class CourseTabBar extends StatelessWidget {
  const CourseTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CourseTab selected;
  final ValueChanged<CourseTab> onSelected;

  static const _labels = {
    CourseTab.syllabus: 'Syllabus',
    CourseTab.assignments: 'Assignments',
    CourseTab.grades: 'Grades',
    CourseTab.about: 'About',
  };

  @override
  Widget build(BuildContext context) {
    return UnderlineTabBar<CourseTab>(
      options: CourseTab.values,
      selected: selected,
      onSelected: onSelected,
      labelFor: (tab) => _labels[tab]!,
    );
  }
}
