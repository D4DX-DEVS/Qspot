import '../../../services/today_service.dart';

/// Short status line for a Today item, e.g. "Due Tomorrow".
extension TodayItemText on TodayLearningItem {
  String metaText(DateTime now) {
    if (status == 'overdue') return 'Past Due - Handle Now';
    final release = releaseAt;
    final due = dueAt;
    // A quiz that has not opened yet is not "due" yet.
    if (kind == 'quiz' && status == 'upcoming' && release != null) {
      return 'Starts ${_day(release, now)}';
    }
    if (due != null) return 'Due ${_day(due, now)}';
    if (release != null) {
      return '${kind == 'schedule' ? 'Live' : 'Available'} ${_day(release, now)}';
    }
    return kind == 'quiz' ? 'Ready to Practice' : 'Open When Ready';
  }

  /// "Today", "Tomorrow" or day/month, by the phone's calendar.
  static String _day(DateTime date, DateTime now) {
    final local = date.toLocal();
    // Calendar days in UTC so a daylight-saving change cannot shift the count.
    final days = DateTime.utc(
      local.year,
      local.month,
      local.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return '${local.day}/${local.month}';
  }
}
