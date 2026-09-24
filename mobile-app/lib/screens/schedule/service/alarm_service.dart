import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../../../services/api_client.dart';
import '../../../services/common/storage_service.dart';
import '../../video/model/video_model.dart';
import '../../video/screens/video_player_screen.dart';

/// Top-level function for handling background notification responses
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint(
    '📱 [ALARM BACKGROUND] Notification action: ${notificationResponse.actionId}, payload: ${notificationResponse.payload}',
  );

  // Stop alarm sound when stop action is tapped
  if (notificationResponse.actionId == 'stop_alarm') {
    FlutterRingtonePlayer().stop();
    debugPrint('🔕 [ALARM BACKGROUND] Alarm stopped via action button');
  } else if (notificationResponse.payload == 'daily_alarm') {
    // Play alarm sound when notification is tapped
    FlutterRingtonePlayer().playAlarm(
      looping: true,
      volume: 1.0,
      asAlarm: true,
    );
    debugPrint('🔔 [ALARM BACKGROUND] Alarm started via notification tap');
  }
}

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _alarmEnabledKey = 'alarm_enabled';
  static const String _alarmTimeKey = 'alarm_time';
  static const int _notificationId = 0;
  static const int _videoReminderBaseId = 1000; // Base ID for video reminders

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Use the device's actual timezone (M22) instead of a hardcoded one,
      // falling back to UTC if the platform lookup fails for any reason.
      String timeZoneName = 'UTC';
      try {
        timeZoneName = await FlutterTimezone.getLocalTimezone();
      } catch (e) {
        debugPrint('⚠️ [ALARM SERVICE] Could not read device timezone: $e');
      }
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        debugPrint(
          '⚠️ [ALARM SERVICE] Unknown timezone "$timeZoneName", using UTC: $e',
        );
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      // Android initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      // iOS initialization settings. Permission is requested lazily, only
      // when the student actually sets a reminder (see [requestPermissions],
      // called from `scheduleAlarm`/`scheduleVideoReminder`) — not eagerly
      // at cold start before login/any UI (M22).
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      // Combined initialization settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      // Create alarm notification channel for Android
      await _createAlarmNotificationChannel();

      _isInitialized = true;
      debugPrint('✅ [ALARM SERVICE] Initialized successfully');

      // Reschedule alarm if it was enabled
      await rescheduleAlarmIfEnabled();

      // Reschedule video reminders
      await rescheduleVideoReminders();

      // Clean up expired reminders
      await StorageService.clearExpiredVideoReminders();
    } catch (e) {
      debugPrint('❌ [ALARM SERVICE] Initialization error: $e');
    }
  }

  /// Create a high-priority alarm notification channel
  Future<void> _createAlarmNotificationChannel() async {
    // Create channel with maximum importance - will use system default notification sound
    // Note: To use actual alarm sound, the app needs to be set as default alarm app
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'qspot_alarm_channel', // id
      'Daily Alarms', // name
      description: 'Channel for daily alarm notifications with sound',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    debugPrint('📢 [ALARM SERVICE] Alarm notification channel created');
  }

  /// Fetches the video and pushes the player, using the app-wide
  /// [navigatorKey] so a reminder notification tap opens the right video
  /// even from a cold start (M22).
  Future<void> _openVideo(String videoId) async {
    try {
      final data = await ApiClient.get('/api/videos/$videoId');
      if (data is! Map<String, dynamic>) return;
      final video = VideoModel.fromJson(data);
      final nav = navigatorKey.currentState;
      if (nav == null) return;
      nav.push(
        MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
      );
    } catch (e) {
      debugPrint('❌ [ALARM SERVICE] Could not open reminder video: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint(
      '📱 [ALARM SERVICE] Notification tapped: ${response.payload}, action: ${response.actionId}',
    );

    // Stop alarm sound when stop action is tapped
    final payload = response.payload;
    if (response.actionId == 'stop_alarm') {
      stopAlarmSound();
      debugPrint('🔕 [ALARM SERVICE] Alarm stopped via action button');
    } else if (payload != null && payload.startsWith('video_')) {
      // Route a video-reminder tap straight to that video (M22).
      _openVideo(payload.substring('video_'.length));
    } else if (response.payload == 'daily_alarm') {
      // If it's the daily alarm notification body tapped, play continuous sound
      playAlarmSound();
      debugPrint('🔔 [ALARM SERVICE] Alarm started via notification tap');
    }
  }

  /// Play continuous alarm sound
  Future<void> playAlarmSound() async {
    try {
      await FlutterRingtonePlayer().playAlarm(
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );
      debugPrint('🔔 [ALARM SERVICE] Playing alarm sound continuously');
    } catch (e) {
      debugPrint('❌ [ALARM SERVICE] Error playing alarm sound: $e');
    }
  }

  /// Stop alarm sound
  Future<void> stopAlarmSound() async {
    try {
      await FlutterRingtonePlayer().stop();
      debugPrint('🔕 [ALARM SERVICE] Alarm sound stopped');
    } catch (e) {
      debugPrint('❌ [ALARM SERVICE] Error stopping alarm sound: $e');
    }
  }

  /// Request notification permissions (especially for iOS and Android 13+)
  Future<bool> requestPermissions() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final bool? granted = await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        // Request notification permission (Android 13+)
        final bool? notificationGranted = await androidImplementation
            ?.requestNotificationsPermission();

        // Request exact alarm permission (Android 12+)
        final bool? exactAlarmGranted = await androidImplementation
            ?.requestExactAlarmsPermission();

        debugPrint(
          '📱 [ALARM SERVICE] Notification permission: $notificationGranted',
        );
        debugPrint(
          '⏰ [ALARM SERVICE] Exact alarm permission: $exactAlarmGranted',
        );

        return (notificationGranted ?? true) && (exactAlarmGranted ?? true);
      }

      return true;
    } catch (e) {
      debugPrint('❌ [ALARM SERVICE] Permission request error: $e');
      return false;
    }
  }

  /// Check if exact alarms are permitted (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        final bool? canSchedule = await androidImplementation
            ?.canScheduleExactNotifications();
        return canSchedule ?? false;
      }
      return true; // iOS and other platforms don't have this restriction
    } catch (e) {
      debugPrint('❌ [ALARM SERVICE] Check exact alarm error: $e');
      return false;
    }
  }

  /// Schedule daily alarm at specified time
  Future<bool> scheduleAlarm(int hour, int minute) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Check if exact alarms are permitted (Android 12+)
      if (defaultTargetPlatform == TargetPlatform.android) {
        final canSchedule = await canScheduleExactAlarms();
        if (!canSchedule) {
          debugPrint(
            '❌ [ALARM SERVICE] Exact alarms not permitted, requesting permission...',
          );
          final granted = await requestPermissions();
          if (!granted) {
            debugPrint('❌ [ALARM SERVICE] User denied exact alarm permission');
            return false;
          }
        }
      }

      // Cancel any existing notifications
      await cancelAlarm();

      // Create notification details with alarm attributes and action buttons.
      // AudioAttributesUsage.alarm uses the device's alarm stream. No
      // `fullScreenIntent` (restricted since Android 14 to real alarm/
      // calendar apps), no `ongoing` (would be a persistent/undismissable
      // notification), no FLAG_INSISTENT (repeats sound indefinitely) — this
      // is a regular high-priority reminder, not a full alarm-clock UI.
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'qspot_alarm_channel', // Use the alarm channel
            'Daily Alarms',
            channelDescription: 'Daily alarm notifications with sound',
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.alarm,
            showWhen: true,
            enableVibration: true,
            playSound: true, // Enable sound for alarm
            channelShowBadge: true,
            autoCancel: true,
            visibility: NotificationVisibility.public,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            ledColor: const Color(0xFFFF0000),
            ledOnMs: 1000,
            ledOffMs: 500,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'stop_alarm',
                'STOP ALARM',
                showsUserInterface: true,
                cancelNotification: true,
              ),
            ],
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Calculate the next occurrence of the alarm time
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the scheduled time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      debugPrint('📅 [ALARM SERVICE] Scheduling alarm for: $scheduledDate');

      // Schedule the notification with full screen intent to wake up device
      await _notifications.zonedSchedule(
        _notificationId,
        '⏰ QSpot Daily Reminder',
        'Alarm is ringing! Tap to stop or use STOP ALARM button.',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
        payload: 'daily_alarm', // Trigger alarm sound when tapped
      );

      // Save alarm settings
      await StorageService.setBool(_alarmEnabledKey, true);
      await StorageService.setString(_alarmTimeKey, '$hour:$minute');

      debugPrint('✅ [ALARM SERVICE] Alarm scheduled successfully');
      return true;
    } catch (e) {
      debugPrint('❌ [ALARM SERVICE] Schedule error: $e');
      return false;
    }
  }

  /// Cancel the alarm
  Future<void> cancelAlarm() async {
    try {
      await _notifications.cancel(_notificationId);
      await stopAlarmSound(); // Stop any playing alarm sound
      await StorageService.setBool(_alarmEnabledKey, false);
      debugPrint('🔕 [ALARM SERVICE] Alarm cancelled');
    } catch (e) {
      debugPrint('❌ [ALARM SERVICE] Cancel error: $e');
    }
  }

  /// Cancels every pending local notification (daily alarm, schedule
  /// reminders, video reminders) and clears the reminder lists. Called on
  /// logout so the next account on this device doesn't inherit the
  /// previous user's reminders (M6).
  Future<void> cancelAllReminders() async {
    try {
      await _notifications.cancelAll();
      await stopAlarmSound();
      await StorageService.setBool(_alarmEnabledKey, false);
      await StorageService.clearAllVideoReminders();
      debugPrint('🔕 [ALARM SERVICE] All reminders cancelled');
    } catch (e) {
      debugPrint('❌ [ALARM SERVICE] Cancel all error: $e');
    }
  }

  /// Check if alarm is enabled
  Future<bool> isAlarmEnabled() async {
    return await StorageService.getBool(_alarmEnabledKey);
  }

  /// Get saved alarm time (returns hour and minute)
  Future<Map<String, int>> getSavedAlarmTime() async {
    try {
      final String timeString = await StorageService.getString(_alarmTimeKey);
      if (timeString.isEmpty) {
        // Default to 6:50 PM
        return {'hour': 18, 'minute': 50};
      }

      final parts = timeString.split(':');
      return {'hour': int.parse(parts[0]), 'minute': int.parse(parts[1])};
    } catch (e) {
      debugPrint('❌ [ALARM SERVICE] Get time error: $e');
      return {'hour': 18, 'minute': 50};
    }
  }

  /// Reschedule alarm if it was previously enabled
  Future<void> rescheduleAlarmIfEnabled() async {
    try {
      final bool isEnabled = await isAlarmEnabled();
      if (isEnabled) {
        final time = await getSavedAlarmTime();
        await scheduleAlarm(time['hour']!, time['minute']!);
        debugPrint('🔄 [ALARM SERVICE] Alarm rescheduled');
      }
    } catch (e) {
      debugPrint('❌ [ALARM SERVICE] Reschedule error: $e');
    }
  }

  /// Schedule video reminder notification
  Future<bool> scheduleVideoReminder(
    String videoId,
    String videoTitle,
    DateTime releaseDate,
  ) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Check if exact alarms are permitted (Android 12+)
      if (defaultTargetPlatform == TargetPlatform.android) {
        final canSchedule = await canScheduleExactAlarms();
        if (!canSchedule) {
          debugPrint(
            '❌ [ALARM SERVICE] Exact alarms not permitted for video reminder',
          );
          final granted = await requestPermissions();
          if (!granted) {
            return false;
          }
        }
      }

      // Request permissions first
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        debugPrint('❌ [ALARM SERVICE] No permission for video reminder');
        return false;
      }

      // Create notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'video_reminders',
            'Video Reminders',
            channelDescription: 'Reminders for upcoming video releases',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Calculate notification time (at the release date)
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        releaseDate,
        tz.local,
      );

      debugPrint(
        '📅 [ALARM SERVICE] Scheduling video reminder for: $scheduledDate',
      );
      debugPrint('📅 [ALARM SERVICE] Video: $videoTitle (ID: $videoId)');

      // Generate unique notification ID from video ID string
      final notificationId = _videoReminderBaseId + videoId.hashCode.abs();

      // Schedule the notification
      await _notifications.zonedSchedule(
        notificationId, // Unique ID for each video
        '🎥 New Video Available!',
        '$videoTitle is now available to watch!',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'video_$videoId', // Pass video ID for future navigation
      );

      // Save video reminder to storage
      await StorageService.addVideoReminder(videoId, videoTitle, releaseDate);

      debugPrint('✅ [ALARM SERVICE] Video reminder scheduled successfully');
      return true;
    } catch (e) {
      debugPrint('❌ [ALARM SERVICE] Video reminder schedule error: $e');
      return false;
    }
  }

  /// Cancel video reminder notification
  Future<void> cancelVideoReminder(String videoId) async {
    try {
      final notificationId = _videoReminderBaseId + videoId.hashCode.abs();
      await _notifications.cancel(notificationId);
      await StorageService.removeVideoReminder(videoId);
      debugPrint(
        '🔕 [ALARM SERVICE] Video reminder cancelled for ID: $videoId',
      );
    } catch (e) {
      debugPrint('❌ [ALARM SERVICE] Cancel video reminder error: $e');
    }
  }

  /// Check if video reminder is set
  Future<bool> hasVideoReminder(String videoId) async {
    return await StorageService.hasVideoReminder(videoId);
  }

  /// Get all scheduled video reminders
  Future<List<Map<String, dynamic>>> getVideoReminders() async {
    return await StorageService.getVideoReminders();
  }

  /// Reschedule all saved video reminders (call on app start)
  Future<void> rescheduleVideoReminders() async {
    try {
      final reminders = await getVideoReminders();

      for (var reminder in reminders) {
        final videoId = reminder['videoId']?.toString() ?? '0';
        final videoTitle = reminder['videoTitle'] as String;
        final releaseDate = DateTime.parse(reminder['releaseDate'] as String);

        // Only reschedule if the release date is in the future
        if (releaseDate.isAfter(DateTime.now())) {
          await scheduleVideoReminder(videoId, videoTitle, releaseDate);
          debugPrint(
            '🔄 [ALARM SERVICE] Rescheduled video reminder: $videoTitle',
          );
        } else {
          // Remove expired reminders
          await cancelVideoReminder(videoId);
          debugPrint(
            '🗑️ [ALARM SERVICE] Removed expired reminder: $videoTitle',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [ALARM SERVICE] Reschedule video reminders error: $e');
    }
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ [ALARM SERVICE] Get pending error: $e');
      return [];
    }
  }
}
