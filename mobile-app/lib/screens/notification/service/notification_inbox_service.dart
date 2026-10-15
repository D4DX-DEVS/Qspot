import '../../../services/api_client.dart';

/// The learner's notification inbox on the server: announcements plus
/// notifications about their own work, with read state kept per account.
class NotificationInboxService {
  /// Raw inbox items, newest first. Falls back to the older public
  /// announcement list when the server has no inbox yet (404) or this
  /// account is not a learner.
  static Future<List<dynamic>> fetch() async {
    try {
      final data = await ApiClient.get('/api/user/notifications');
      if (data is Map && data['items'] is List) return data['items'] as List;
      return const [];
    } on ApiException catch (e) {
      if (e.status != 404 && e.status != 403) rethrow;
      final data = await ApiClient.get('/api/notifications');
      if (data is List) return data;
      return data is Map ? (data['data'] as List? ?? const []) : const [];
    }
  }

  static Future<void> markRead(String id) async {
    try {
      await ApiClient.post('/api/user/notifications/$id/read', body: {});
    } catch (_) {
      // The phone remembers it as read too; the server catches up next time.
    }
  }

  static Future<void> markAllRead() async {
    try {
      await ApiClient.post('/api/user/notifications/read-all', body: {});
    } catch (_) {}
  }
}
