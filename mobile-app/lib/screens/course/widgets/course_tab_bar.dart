import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../model/course_tab.dart';

/// Two-way switch between the sections of the course page.
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
    CourseTab.grades: 'Grades',
    CourseTab.about: 'About',
  };

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.brandSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final tab in CourseTab.values)
            Expanded(child: _segment(palette, tab)),
        ],
      ),
    );
  }

  Widget _segment(HomePalette palette, CourseTab tab) {
    final active = tab == selected;
    return Semantics(
      button: true,
      selected: active,
      excludeSemantics: true,
      label: _labels[tab],
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(tab),
        child: Container(
          alignment: Alignment.center,
          constraints: const BoxConstraints(minHeight: 40),
          decoration: BoxDecoration(
            color: active ? palette.card : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _labels[tab]!,
            style: AppFonts.semiBold(
              color: active ? palette.brand : palette.textMuted,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
