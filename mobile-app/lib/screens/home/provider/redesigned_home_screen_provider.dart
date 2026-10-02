import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../services/today_service.dart';
import '../model/today_plan.dart';

/// Screen-local state for the redesigned home screen: today's learning
/// overview (next item, upcoming items, streak) and the plan built from it.
class RedesignedHomeScreenProvider extends ChangeNotifier {
  /// Coming back to the Today tab within this time does not fetch again.
  static const _tabRefreshGap = Duration(seconds: 15);

  TodayOverview? _today;
  TodayPlan _plan = const TodayPlan();
  DateTime? _loadedAt;
  bool _tabVisible = true;
  bool _disposed = false;

  TodayOverview? get today => _today;
  TodayPlan get plan => _plan;

  Future<void> loadToday() async {
    final result = await TodayService.fetch();
    if (_disposed) return;
    // A failed refresh keeps what the learner already sees.
    if (result == null && _today != null) return;
    _today = result;
    _plan = TodayPlan.fromOverview(result);
    _loadedAt = DateTime.now();
    notifyListeners();
  }

  /// Tells the provider whether the Today tab is the one on screen. Coming
  /// back to it reloads, so work finished elsewhere drops off the list.
  void setTabVisible(bool visible) {
    final comingBack = visible && !_tabVisible;
    _tabVisible = visible;
    if (!comingBack) return;
    final loadedAt = _loadedAt;
    if (loadedAt != null &&
        DateTime.now().difference(loadedAt) < _tabRefreshGap) {
      return;
    }
    unawaited(loadToday());
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
