import 'package:flutter/foundation.dart';
import '../../../services/api_client.dart';
import '../model/notification_model.dart';
import '../service/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Set<String> _readNotificationIds = <String>{};

  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage.isNotEmpty;
  String get errorMessage => _errorMessage;
  int get notificationsCount => _notifications.length;
  int get unreadCount =>
      _notifications.where((n) => !_readNotificationIds.contains(n.id)).length;

  // Get notifications with read status
  List<NotificationModel> get notificationsWithReadStatus {
    return _notifications.map((notification) {
      return notification.copyWith(
        isRead: _readNotificationIds.contains(notification.id),
      );
    }).toList();
  }

  // Initialize notifications
  Future<void> initialize() async {
    await _loadReadNotifications();
    await loadNotifications();
  }

  // Load read notifications from local storage
  Future<void> _loadReadNotifications() async {
    _readNotificationIds = await NotificationService.getReadNotifications();
  }

  // Load all notifications
  Future<void> loadNotifications() async {
    _setLoading(true);
    _clearError();

    try {
      final dynamic data = await ApiClient.get('/api/notifications');
      final List<dynamic> notificationsJson = data is List
          ? data
          : (data is Map ? (data['data'] ?? []) : []);
      _notifications = notificationsJson
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      await _loadReadNotifications(); // Refresh read status
      notifyListeners();
    } on ApiException catch (e) {
      if (e.status == 404) {
        _notifications = [];
        notifyListeners();
      } else {
        _setError(e.message);
      }
    } catch (e) {
      _setError('Failed to load notifications');
    } finally {
      _setLoading(false);
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await NotificationService.markAsRead(notificationId);
      _readNotificationIds.add(notificationId);
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  // Mark notification as unread
  Future<void> markAsUnread(String notificationId) async {
    try {
      await NotificationService.markAsUnread(notificationId);
      _readNotificationIds.remove(notificationId);
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final notificationIds = _notifications.map((n) => n.id).toList();
      await NotificationService.markAllAsRead(notificationIds);
      _readNotificationIds.addAll(notificationIds);
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  // Check if notification is read
  bool isNotificationRead(String notificationId) {
    return _readNotificationIds.contains(notificationId);
  }

  // Get notification by ID
  NotificationModel? getNotificationById(String id) {
    try {
      return _notifications.firstWhere((notification) => notification.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search notifications
  List<NotificationModel> searchNotifications(String query) {
    if (query.isEmpty) return notificationsWithReadStatus;

    final lowercaseQuery = query.toLowerCase();
    return notificationsWithReadStatus.where((notification) {
      return notification.title.toLowerCase().contains(lowercaseQuery) ||
          notification.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Refresh notifications
  Future<void> refresh() async {
    await loadNotifications();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }

  /// Resets in-memory state and the local read-state cache. Call on logout
  /// so the next account on this device doesn't inherit read/unread state
  /// from the previous one (M6).
  Future<void> clear() async {
    _notifications = [];
    _readNotificationIds = <String>{};
    _errorMessage = '';
    _isLoading = false;
    await NotificationService.clearAllRead();
    notifyListeners();
  }
}
