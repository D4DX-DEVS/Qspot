import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../screens/schedule/service/alarm_service.dart';
import 'common/storage_service.dart';

/// A phone notification shortly before a started quiz closes, so a student
/// who left the app comes back and submits. Scheduled when the quiz is opened
/// and cancelled once the server has the answers (or has refused them).
///
/// Notification permission is asked for once, with an explanation first, by
/// [askPermissionOnce]; a student who says no simply gets no reminder. Never
/// throws.
class QuizReminderService {
  QuizReminderService._();

  /// How long before the quiz closes the reminder fires.
  static const Duration lead = Duration(minutes: 5);

  // Above every video reminder id (AlarmService uses 1000 + a 30-bit hash),
  // and the range stays below the 32-bit limit.
  static const int _baseId = 1073742824;

  static const String _askedKey = 'quiz_reminder_permission_asked';

  /// Whether the phone already lets the app show notifications.
  @visibleForTesting
  static Future<bool> Function() notificationsAllowed = _notificationsAllowed;

  /// Shows the phone's own notification permission prompt.
  @visibleForTesting
  static Future<void> Function() requestNotifications = _requestNotifications;

  /// The first time a quiz is started, if notifications are not allowed yet:
  /// [explain] tells the student what the reminder is for and resolves to
  /// true to go ahead, then the phone's own prompt appears. Asked only once,
  /// whatever the answer.
  static Future<void> askPermissionOnce(Future<bool> Function() explain) async {
    try {
      if (await StorageService.getBool(_askedKey)) return;
      if (await notificationsAllowed()) {
        await StorageService.setBool(_askedKey, true);
        return;
      }
      final allow = await explain();
      await StorageService.setBool(_askedKey, true);
      if (allow) await requestNotifications();
    } catch (e) {
      debugPrint('Quiz reminder permission not asked: $e');
    }
  }

  static Future<bool> _notificationsAllowed() async {
    final plugin = FlutterLocalNotificationsPlugin();
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) return (await ios.checkPermissions())?.isEnabled ?? false;
    return true; // nothing to ask on other platforms
  }

  // Only notifications: the exact-alarm settings page is not opened, so on
  // Android the reminder may come a few minutes late without that permission.
  static Future<void> _requestNotifications() async {
    await AlarmService().initialize();
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, sound: true);
  }

  /// When to remind for a quiz closing at [closesAt]; null when that moment
  /// has already passed.
  static DateTime? remindAt(DateTime closesAt, DateTime now) {
    final at = closesAt.subtract(lead);
    return at.isAfter(now) ? at : null;
  }

  /// The same id for a quiz on every run, so the reminder can be replaced or
  /// cancelled later.
  static int idFor(String quizId) =>
      _baseId +
      quizId.codeUnits.fold<int>(0, (h, c) => (h * 31 + c) % 1000000007) %
          1000000000;

  static Future<void> schedule({
    required String quizId,
    required String title,
    required DateTime closesAt,
  }) async {
    final at = remindAt(closesAt, clock.now());
    if (at == null) return;
    try {
      final alarms = AlarmService();
      await alarms.initialize();
      final exact = await alarms.canScheduleExactAlarms();
      await FlutterLocalNotificationsPlugin().zonedSchedule(
        idFor(quizId),
        'Quiz closes in 5 minutes',
        '${title.isEmpty ? 'Your quiz' : title} — open Qspot to finish and '
            'submit your answers.',
        tz.TZDateTime.from(at, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'quiz_reminders',
            'Quiz Reminders',
            channelDescription: 'Reminders to submit a quiz before it closes',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'quiz_$quizId',
      );
    } catch (e) {
      debugPrint('Quiz reminder not scheduled: $e');
    }
  }

  static Future<void> cancel(String quizId) async {
    try {
      await FlutterLocalNotificationsPlugin().cancel(idFor(quizId));
    } catch (e) {
      debugPrint('Quiz reminder not cancelled: $e');
    }
  }
}
