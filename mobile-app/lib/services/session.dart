import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/auth/provider/auth_provider.dart';
import '../screens/auth/screens/login_screen.dart';
import '../screens/bookmark/provider/bookmark_provider.dart';
import '../screens/notification/provider/notification_provider.dart';
import '../screens/quiz/provider/quiz_provider.dart';
import '../screens/quiz/widgets/quiz_logout_warning_dialog.dart';
import '../screens/schedule/provider/schedule_provider.dart';
import '../screens/schedule/service/alarm_service.dart';
import '../screens/video/provider/video_provider.dart';
import '../widgets/common/logout_confirm_dialog.dart';

/// Asks before logging out. With quiz answers on this phone that never reached
/// the server, it warns that logging out deletes them; otherwise it asks the
/// usual "Are you sure?". Resolves to true when the student goes ahead.
Future<bool> confirmLogout(BuildContext context) async {
  final unsent = await Provider.of<QuizProvider>(
    context,
    listen: false,
  ).unsentQuizCount();
  if (!context.mounted) return false;
  return unsent > 0
      ? QuizLogoutWarningDialog.show(context, unsent)
      : showLogoutConfirmDialog(context);
}

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
  // Saved quiz answers belong to this student only; the warning in
  // [confirmLogout] told them about any that were never sent.
  await quizProvider.deleteSavedQuizzes();
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
