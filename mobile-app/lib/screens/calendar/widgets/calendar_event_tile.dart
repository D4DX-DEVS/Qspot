import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/common/tone_chip.dart';
import '../model/calendar_event.dart';
import 'calendar_kind_style.dart';

/// One entry on the agenda: its time, its title and what kind it is, and a
/// chip saying what happens then ("Due", "Live"...). Overdue ones show red.
class CalendarEventTile extends StatelessWidget {
  const CalendarEventTile({
    super.key,
    required this.event,
    required this.onTap,
  });

  final CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final when = event.when;
    final time = when == null ? 'Anytime' : DateFormat('h:mm a').format(when);
    final tone = event.isOverdue ? palette.coral : event.kind.tone(palette);
    return Semantics(
      button: true,
      label: '${event.title}. ${event.detail}. ${event.action}, $time.',
      excludeSemantics: true,
      child: SurfaceCard(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  time,
                  style: AppFonts.bold(color: palette.text, fontSize: 12.5),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppFonts.bold(
                      color: palette.text,
                      fontSize: 13.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.detail,
                    style: AppFonts.regular(
                      color: palette.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ToneChip(label: event.action, tone: tone),
          ],
        ),
      ),
    );
  }
}
