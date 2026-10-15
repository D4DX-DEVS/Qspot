import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/surface_card.dart';
import '../model/calendar_dates.dart';
import '../model/calendar_event_kind.dart';
import 'calendar_day_cell.dart';

/// The week on show: its month, arrows to change week, and the seven days.
/// An arrow with no handler is greyed out.
class CalendarWeekStrip extends StatelessWidget {
  const CalendarWeekStrip({
    super.key,
    required this.label,
    required this.days,
    required this.today,
    required this.selected,
    required this.kindsFor,
    required this.onDayTap,
    this.onPrevious,
    this.onNext,
  });

  final String label;
  final List<DateTime> days;
  final DateTime today;
  final DateTime? selected;
  final List<CalendarEventKind> Function(DateTime day) kindsFor;
  final ValueChanged<DateTime> onDayTap;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return SurfaceCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    label,
                    style: AppFonts.bold(color: palette.text, fontSize: 14),
                  ),
                ),
              ),
              IconButton(
                onPressed: onPrevious,
                tooltip: 'Previous week',
                icon: const Icon(LucideIcons.chevronLeft, size: 20),
              ),
              IconButton(
                onPressed: onNext,
                tooltip: 'Next week',
                icon: const Icon(LucideIcons.chevronRight, size: 20),
              ),
            ],
          ),
          Row(
            children: [
              for (final day in days)
                Expanded(
                  child: CalendarDayCell(
                    day: day,
                    isToday: day.isSameDay(today),
                    isSelected: selected?.isSameDay(day) ?? false,
                    kinds: kindsFor(day),
                    onTap: () => onDayTap(day),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
