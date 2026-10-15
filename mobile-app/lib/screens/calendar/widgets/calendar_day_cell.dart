import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../model/calendar_event_kind.dart';
import 'calendar_kind_style.dart';

/// One day of the week strip: its weekday, its date in a circle (filled for
/// today, outlined when chosen) and a dot for each kind of entry on it.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.kinds,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final List<CalendarEventKind> kinds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final fill = isToday
        ? palette.brand
        : isSelected
        ? palette.brandSoft
        : Colors.transparent;
    final numberColor = isToday
        ? Theme.of(context).colorScheme.onPrimary
        : isSelected
        ? palette.brand
        : palette.text;
    final spoken = [
      DateFormat('EEEE d MMMM').format(day),
      if (isToday) 'today',
      if (kinds.isNotEmpty) kinds.map((kind) => kind.label).join(', '),
    ].join(', ');
    return Semantics(
      button: true,
      selected: isSelected,
      label: spoken,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  DateFormat('E').format(day),
                  style: AppFonts.bold(color: palette.textMuted, fontSize: 11),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: fill,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: palette.brand, width: 1.5)
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${day.day}',
                    style: AppFonts.bold(color: numberColor, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final kind in kinds)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: kind.tone(palette).color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
