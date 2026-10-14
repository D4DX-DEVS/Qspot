import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
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
    final palette = HomePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.brandSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final tab in LessonTab.values)
            Expanded(child: _segment(palette, tab)),
        ],
      ),
    );
  }

  Widget _segment(HomePalette palette, LessonTab tab) {
    final active = tab == selected;
    final locked = tab == LessonTab.practice && practiceLocked;
    final color = active ? palette.brand : palette.textMuted;
    return Semantics(
      button: true,
      selected: active,
      excludeSemantics: true,
      label: locked ? '${_labels[tab]}, locked' : _labels[tab],
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _labels[tab]!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.semiBold(color: color, fontSize: 13),
                ),
              ),
              if (locked) ...[
                const SizedBox(width: 4),
                Icon(LucideIcons.lock, size: 12, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
