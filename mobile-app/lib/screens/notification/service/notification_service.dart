import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _readNotificationsKey = 'read_notifications';

  // Get list of read notification IDs
  static Future<Set<String>> getReadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotificationsJson =
          prefs.getStringList(_readNotificationsKey) ?? [];
      return readNotificationsJson.toSet();
    } catch (e) {
      return <String>{};
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = await getReadNotifications();
      readNotifications.add(notificationId);

      final readNotificationsJson = readNotifications.toList();
      await prefs.setStringList(_readNotificationsKey, readNotificationsJson);
    } catch (e) {
      // Handle error silently
    }
  }

  // Mark notification as unread
  static Future<void> markAsUnread(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = await getReadNotifications();
      readNotifications.remove(notificationId);

      final readNotificationsJson = readNotifications.toList();
      await prefs.setStringList(_readNotificationsKey, readNotificationsJson);
    } catch (e) {
      // Handle error silently
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead(List<String> notificationIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = await getReadNotifications();
      readNotifications.addAll(notificationIds);

      final readNotificationsJson = readNotifications.toList();
      await prefs.setStringList(_readNotificationsKey, readNotificationsJson);
    } catch (e) {
      // Handle error silently
    }
  }

  // Clear all read notifications
  static Future<void> clearAllRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_readNotificationsKey);
    } catch (e) {
      // Handle error silently
    }
  }
}
