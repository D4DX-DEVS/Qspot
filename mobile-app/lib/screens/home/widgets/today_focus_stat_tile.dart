import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/home_palette.dart';
import '../../../widgets/common/stat_tile.dart';
import '../model/today_section.dart';

/// Stat tile that follows what matters most to the learner right now:
/// overdue work, then work to do, then what is coming up.
class TodayFocusStatTile extends StatelessWidget {
  const TodayFocusStatTile({
    super.key,
    required this.focus,
    required this.count,
  });

  /// [TodaySection.attention], [TodaySection.todo] or
  /// [TodaySection.comingUp]; anything else is shown as "Coming Up".
  final TodaySection focus;
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final (icon, color, label) = switch (focus) {
      TodaySection.attention => (
        LucideIcons.triangleAlert,
        palette.coral.color,
        'Overdue',
      ),
      TodaySection.todo => (LucideIcons.listTodo, palette.rose.color, 'To Do'),
      _ => (LucideIcons.calendarDays, palette.amber.color, 'Coming Up'),
    };
    return StatTile(icon: icon, color: color, value: '$count', label: label);
  }
}
