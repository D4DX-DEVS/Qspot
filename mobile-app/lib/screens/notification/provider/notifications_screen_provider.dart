import 'package:flutter/foundation.dart';

import '../model/notification_model.dart';
import 'notification_provider.dart';

/// Screen-local state for the notifications screen: the list currently shown
/// after applying the search query.
class NotificationsScreenProvider extends ChangeNotifier {
  List<NotificationModel> _filteredNotifications = [];

  List<NotificationModel> get filteredNotifications => _filteredNotifications;

  /// Re-applies [query] against [source]; an empty query shows everything.
  void updateFiltered(NotificationProvider source, String query) {
    if (query.isEmpty) {
      _filteredNotifications = source.notificationsWithReadStatus;
    } else {
      _filteredNotifications = source.searchNotifications(query);
    }
    notifyListeners();
  }
}
