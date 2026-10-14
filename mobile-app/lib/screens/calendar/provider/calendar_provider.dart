import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../services/today_service.dart';
import '../../../utils/user_friendly_error.dart';
import '../model/calendar_agenda.dart';
import '../model/calendar_dates.dart';
import '../model/calendar_event_kind.dart';
import '../model/calendar_filter.dart';
import '../model/calendar_section.dart';

/// State of the Calendar: the learner's dated work, the week on show, the
/// day they tapped and the kind filter.
class CalendarProvider extends ChangeNotifier {
  CalendarProvider({
    Future<TodayOverview?> Function()? fetch,
    DateTime Function()? clock,
  }) : _fetch = fetch ?? _fetchLongList,
       _clock = clock ?? DateTime.now {
    _weekStart = _clock().weekStart;
  }

  /// Longer than the short list Today shows, so later weeks are not empty
  /// just because the list was cut.
  static const upcomingLimit = 200;

  static Future<TodayOverview?> _fetchLongList() =>
      TodayService.fetchWithErrors(upcomingLimit: upcomingLimit);

  final Future<TodayOverview?> Function() _fetch;
  final DateTime Function() _clock;

  CalendarAgenda _agenda = const CalendarAgenda.empty();
  CalendarFilter _filter = CalendarFilter.all;
  late DateTime _weekStart;
  DateTime? _selectedDay;
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  bool _disposed = false;

  CalendarAgenda get agenda => _agenda;
  CalendarFilter get filter => _filter;
  DateTime? get selectedDay => _selectedDay;
  bool get isLoading => _loading;
  String? get error => _error;

  /// First load: nothing to show yet.
  bool get showSkeleton => _loading && !_loaded && _error == null;

  /// Failed with nothing to fall back on.
  bool get showError => !_loading && _error != null && !_loaded;

  /// Loaded, and the learner has nothing dated coming up.
  bool get isEmpty => _loaded && _agenda.isEmpty;

  /// Monday to Sunday of the week on show.
  List<DateTime> get weekDays => [
    for (var i = 0; i < 7; i++) _weekStart.plusDays(i),
  ];

  /// "October 2026", or "Oct – Nov 2026" when the week crosses months.
  String get weekLabel {
    final first = _weekStart;
    final last = _weekStart.plusDays(6);
    if (first.month == last.month) return DateFormat('MMMM yyyy').format(first);
    if (first.year == last.year) {
      return '${DateFormat('MMM').format(first)} – '
          '${DateFormat('MMM yyyy').format(last)}';
    }
    return '${DateFormat('MMM yyyy').format(first)} – '
        '${DateFormat('MMM yyyy').format(last)}';
  }

  /// Nothing is listed before this week, so there is no going back past it.
  bool get canGoBack => _weekStart.isAfter(_clock().weekStart);

  /// Weeks after the last dated entry would only be empty.
  bool get canGoForward => _agenda.hasEventOnOrAfter(_weekStart.plusDays(7));

  /// Now, by the clock the Calendar was given.
  DateTime get today => _clock();

  bool isToday(DateTime day) => day.isSameDay(_clock());

  bool isSelected(DateTime day) => _selectedDay?.isSameDay(day) ?? false;

  /// Dots under a day: one per kind of entry on it.
  List<CalendarEventKind> kindsOn(DateTime day) =>
      _agenda.kindsOn(day, _filter);

  /// The agenda as the screen lists it, for the filter and day chosen.
  List<CalendarSection> get sections =>
      _agenda.sections(now: _clock(), filter: _filter, day: _selectedDay);

  Future<void> load() async {
    _loading = true;
    _error = null;
    _notify();
    try {
      _agenda = CalendarAgenda.fromOverview(await _fetch());
      _loaded = true;
    } catch (error) {
      debugPrint('Calendar load failed: $error');
      _error = userFriendlyError(error);
    } finally {
      _loading = false;
      _notify();
    }
  }

  void selectFilter(CalendarFilter filter) {
    if (filter == _filter) return;
    _filter = filter;
    _notify();
  }

  /// Tapping the day that is already chosen shows every day again.
  void toggleDay(DateTime day) {
    _selectedDay = isSelected(day) ? null : day.dayOnly;
    _notify();
  }

  void clearDay() {
    if (_selectedDay == null) return;
    _selectedDay = null;
    _notify();
  }

  void showPreviousWeek() => _moveWeek(-1, allowed: canGoBack);

  void showNextWeek() => _moveWeek(1, allowed: canGoForward);

  void _moveWeek(int weeks, {required bool allowed}) {
    if (!allowed) return;
    _weekStart = _weekStart.plusDays(7 * weeks);
    // The chosen day belongs to the week just left, so it would be out of
    // view.
    _selectedDay = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
