import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../model/calendar_event.dart';
import '../model/calendar_section.dart';
import 'calendar_event_tile.dart';

/// A day (or "Overdue") heading with its entries underneath. An optional
/// link on the heading line, e.g. "Show all".
class CalendarSectionView extends StatelessWidget {
  const CalendarSectionView({
    super.key,
    required this.section,
    required this.onEventTap,
    this.actionLabel,
    this.onAction,
  });

  final CalendarSection section;
  final ValueChanged<CalendarEvent> onEventTap;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  section.title,
                  style: AppFonts.bold(
                    color: section.isOverdue
                        ? palette.coral.color
                        : palette.textMuted,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    style: AppFonts.semiBold(
                      color: palette.brand,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (final event in section.events) ...[
          CalendarEventTile(event: event, onTap: () => onEventTap(event)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
