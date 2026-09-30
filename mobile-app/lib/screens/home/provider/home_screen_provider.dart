import 'package:flutter/foundation.dart';

import '../../../services/course_service.dart';
import '../../../services/today_service.dart';

/// Screen-local state for the legacy home screen: active courses and today's
/// learning overview.
class HomeScreenProvider extends ChangeNotifier {
  List<CourseModel> _courses = [];
  TodayOverview? _todayOverview;
  bool _disposed = false;

  List<CourseModel> get courses => _courses;
  TodayOverview? get todayOverview => _todayOverview;

  Future<void> loadCourses() async {
    final courses = await CourseService.fetchActive();
    if (_disposed) return;
    _courses = courses;
    notifyListeners();
  }

  Future<void> loadTodayOverview() async {
    final overview = await TodayService.fetch();
    if (_disposed) return;
    _todayOverview = overview;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
