import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/auth/provider/auth_provider.dart';
import '../screens/auth/screens/login_screen.dart';
import '../screens/bookmark/provider/bookmark_provider.dart';
import '../screens/notification/provider/notification_provider.dart';
import '../screens/quiz/provider/quiz_provider.dart';
import '../screens/schedule/provider/schedule_provider.dart';
import '../screens/schedule/service/alarm_service.dart';
import '../screens/video/provider/video_provider.dart';

/// Logs the current user out: clears every provider/service that caches
/// per-account data (video progress, bookmarks, quiz state, notification
/// read-state, local reminders) so the next login on this device never
/// inherits a stale account's data (M6), then routes to [LoginScreen].
///
/// Grabs everything it needs from [context] before the first `await`, so it
/// never touches a possibly-unmounted [BuildContext] after an async gap.
Future<void> performLogout(BuildContext context) async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final videoProvider = Provider.of<VideoProvider>(context, listen: false);
  final bookmarkProvider = Provider.of<BookmarkProvider>(
    context,
    listen: false,
  );
  final quizProvider = Provider.of<QuizProvider>(context, listen: false);
  final notificationProvider = Provider.of<NotificationProvider>(
    context,
    listen: false,
  );
  final scheduleProvider = Provider.of<ScheduleProvider>(
    context,
    listen: false,
  );
  final navigator = Navigator.of(context);

  videoProvider.clear();
  bookmarkProvider.clear();
  quizProvider.clear();
  await notificationProvider.clear();
  scheduleProvider.clear();
  await AlarmService().cancelAllReminders();

  await authProvider.logout();

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}
