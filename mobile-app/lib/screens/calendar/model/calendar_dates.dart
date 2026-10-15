/// Calendar-day helpers, by the phone's own calendar. Dates are rebuilt from
/// year, month and day so a daylight-saving change cannot shift them.
extension CalendarDates on DateTime {
  /// The same day at midnight.
  DateTime get dayOnly => DateTime(year, month, day);

  /// The Monday of this date's week, at midnight.
  DateTime get weekStart => DateTime(year, month, day - (weekday - 1));

  DateTime plusDays(int days) => DateTime(year, month, day + days);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
