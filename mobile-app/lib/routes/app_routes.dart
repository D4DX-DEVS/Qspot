import 'package:flutter/material.dart';

import '../screens/assignment/screens/assignments_screen.dart';
import '../screens/calendar/screens/calendar_screen.dart';
import '../screens/certificate/screens/certificates_screen.dart';
import '../screens/common/widgets/home_theme_scope.dart';
import '../screens/grades/screens/grades_screen.dart';
import '../screens/quiz/screens/quiz_list_screen.dart';
import '../screens/schedule/screens/schedule_screen.dart';

/// The learner screens that can be opened by name, and the one place that
/// turns a name into a page. Opening by name is what lets a notification or
/// a link take someone straight to a screen. Screens that need data passed in
/// (a course, a lesson) are not here.
class AppRoutes {
  AppRoutes._();

  static const calendar = '/calendar';
  static const grades = '/grades';
  static const certificates = '/certificates';
  static const assignments = '/assignments';
  static const quizzes = '/quizzes';
  static const schedule = '/schedule';

  /// Every name in the table.
  static const names = [
    calendar,
    grades,
    certificates,
    assignments,
    quizzes,
    schedule,
  ];

  /// Set as `MaterialApp.onGenerateRoute`. Returns null for a name that is
  /// not in the table, so the app's own fallback handles it.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final Widget? page = switch (settings.name) {
      calendar => const CalendarScreen(),
      grades => const GradesScreen(),
      certificates => const CertificatesScreen(),
      assignments => const AssignmentsScreen(),
      quizzes => const QuizListScreen(),
      schedule => const ScheduleScreen(),
      _ => null,
    };
    if (page == null) return null;
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => HomeThemeScope(child: page),
    );
  }
}
