import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/filter_chip_bar.dart';
import '../../../widgets/common/loading_skeleton.dart';
import '../../../widgets/common/state_message_view.dart';
import '../../assignment/screens/assignments_screen.dart';
import '../../quiz/screens/quiz_list_screen.dart';
import '../../schedule/screens/schedule_screen.dart';
import '../model/calendar_event.dart';
import '../model/calendar_event_kind.dart';
import '../model/calendar_filter.dart';
import '../provider/calendar_provider.dart';
import '../widgets/calendar_no_entries.dart';
import '../widgets/calendar_section_view.dart';
import '../widgets/calendar_week_strip.dart';

/// Everything with a date that the learner still has to do: assignments
/// due, quizzes, live classes and lessons that open later. A week strip on
/// top, the kind filters, then the agenda day by day.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key, this.clock});

  /// Replaces the phone's clock, for tests.
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarProvider(clock: clock)..load(),
      child: Consumer<CalendarProvider>(
        builder: (context, calendar, _) => Scaffold(
          appBar: const CommonAppBar(title: 'Calendar'),
          body: _body(context, calendar),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, CalendarProvider calendar) {
    if (calendar.showSkeleton) return const LoadingSkeleton();
    if (calendar.showError) {
      return StateMessageView(
        icon: LucideIcons.wifiOff,
        title: 'Could Not Load Calendar',
        message: calendar.error ?? 'Check your connection and try again.',
        onRetry: calendar.load,
      );
    }
    if (calendar.isEmpty) {
      return RefreshIndicator(
        onRefresh: calendar.load,
        child: LayoutBuilder(
          builder: (context, box) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: box.maxHeight,
                child: const StateMessageView(
                  icon: LucideIcons.calendarDays,
                  title: 'Nothing Coming Up',
                  message:
                      'Assignments, quizzes, live classes and lessons with a date will show up here.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sections = calendar.sections;
    final onDay = calendar.selectedDay != null;
    return RefreshIndicator(
      onRefresh: calendar.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppTheme.contentInset,
          8,
          AppTheme.contentInset,
          28 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          CalendarWeekStrip(
            label: calendar.weekLabel,
            days: calendar.weekDays,
            today: calendar.today,
            selected: calendar.selectedDay,
            kindsFor: calendar.kindsOn,
            onDayTap: calendar.toggleDay,
            onPrevious: calendar.canGoBack ? calendar.showPreviousWeek : null,
            onNext: calendar.canGoForward ? calendar.showNextWeek : null,
          ),
          const SizedBox(height: 12),
          FilterChipBar<CalendarFilter>(
            options: CalendarFilter.values,
            selected: calendar.filter,
            onSelected: calendar.selectFilter,
            labelFor: (filter) => filter.label,
          ),
          const SizedBox(height: 8),
          if (sections.isEmpty)
            CalendarNoEntries(
              title: onDay ? 'Nothing on This Day' : 'Nothing Here',
              message: onDay
                  ? 'No entries on this day.'
                  : 'No entries of this kind.',
              actionLabel: onDay ? 'Show all days' : null,
              onAction: calendar.clearDay,
            ),
          for (final section in sections)
            CalendarSectionView(
              section: section,
              onEventTap: (event) => _open(context, calendar, event),
              actionLabel: onDay ? 'Show all days' : null,
              onAction: calendar.clearDay,
            ),
        ],
      ),
    );
  }

  /// Opens the area an entry belongs to, then refreshes, since the learner
  /// may have finished it there.
  void _open(BuildContext context, CalendarProvider calendar, CalendarEvent e) {
    final Widget? page = switch (e.kind) {
      CalendarEventKind.assignment => const AssignmentsScreen(),
      CalendarEventKind.quiz => const QuizListScreen(),
      CalendarEventKind.liveClass => const ScheduleScreen(),
      CalendarEventKind.lesson => null,
    };
    if (page == null) {
      AppSnackBar.show(
        context,
        message: e.notOpenMessage,
        color: AppColors.warningOrange,
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) => calendar.load());
  }
}
