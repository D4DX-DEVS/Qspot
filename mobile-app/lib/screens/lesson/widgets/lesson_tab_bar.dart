import 'package:flutter/material.dart';

import '../../../widgets/common/underline_tab_bar.dart';
import '../model/lesson_tab.dart';

/// Switch between the notes, downloads and practice of a lesson. Practice
/// shows a lock until the lesson is finished.
class LessonTabBar extends StatelessWidget {
  const LessonTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.practiceLocked,
  });

  final LessonTab selected;
  final ValueChanged<LessonTab> onSelected;
  final bool practiceLocked;

  static const _labels = {
    LessonTab.learn: 'Learn',
    LessonTab.downloads: 'Downloads',
    LessonTab.practice: 'Practice',
  };

  @override
  Widget build(BuildContext context) {
    return UnderlineTabBar<LessonTab>(
      options: LessonTab.values,
      selected: selected,
      onSelected: onSelected,
      labelFor: (tab) => _labels[tab]!,
      isLocked: (tab) => tab == LessonTab.practice && practiceLocked,
    );
  }
}
