import 'package:flutter/foundation.dart';

import '../../../utils/user_friendly_error.dart';
import '../model/grade_entry.dart';
import '../model/grade_filter.dart';
import '../service/grades_service.dart';

/// State of the My Grades screen: every mark the learner has, newest first,
/// narrowed by the selected filter.
class GradesProvider extends ChangeNotifier {
  GradesProvider({Future<List<GradeEntry>> Function()? fetch})
    : _fetch = fetch ?? GradesService.fetch;

  final Future<List<GradeEntry>> Function() _fetch;

  List<GradeEntry> _entries = const [];
  GradeFilter _filter = GradeFilter.all;
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  bool _disposed = false;

  /// Every mark, newest first.
  List<GradeEntry> get entries => _entries;
  GradeFilter get filter => _filter;
  bool get isLoading => _loading;
  String? get error => _error;

  /// The marks the selected filter shows.
  List<GradeEntry> get visible => [
    for (final entry in _entries)
      if (_filter.matches(entry.kind)) entry,
  ];

  /// First load: nothing to show yet.
  bool get showSkeleton => _loading && !_loaded && _error == null;

  /// Failed with nothing to fall back on.
  bool get showError => !_loading && _error != null && _entries.isEmpty;

  /// Loaded, and the learner has no marks yet.
  bool get isEmpty => _loaded && _entries.isEmpty;

  /// The mean of every mark as a percentage, or null when there are none.
  double? get average {
    if (_entries.isEmpty) return null;
    final total = _entries.fold<double>(0, (sum, entry) => sum + entry.percent);
    return total / _entries.length;
  }

  /// How many marks a filter would show.
  int countFor(GradeFilter filter) =>
      _entries.where((entry) => filter.matches(entry.kind)).length;

  Future<void> load() async {
    _loading = true;
    _error = null;
    _notify();
    try {
      _entries = sortNewestFirst(await _fetch());
      _loaded = true;
    } catch (error) {
      debugPrint('Grades load failed: $error');
      _error = userFriendlyError(error);
    } finally {
      _loading = false;
      _notify();
    }
  }

  void selectFilter(GradeFilter filter) {
    if (filter == _filter) return;
    _filter = filter;
    _notify();
  }

  /// Newest first; marks with no date go last.
  static List<GradeEntry> sortNewestFirst(Iterable<GradeEntry> entries) {
    return entries.toList()..sort((a, b) {
      final aDate = a.date;
      final bDate = b.date;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
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
