import 'package:flutter/foundation.dart';

import '../../../services/today_service.dart';

/// Screen-local state for the redesigned home screen: today's learning
/// overview (next item, upcoming items, streak).
class RedesignedHomeScreenProvider extends ChangeNotifier {
  TodayOverview? _today;
  bool _disposed = false;

  TodayOverview? get today => _today;

  Future<void> loadToday() async {
    final result = await TodayService.fetch();
    if (_disposed) return;
    _today = result;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
