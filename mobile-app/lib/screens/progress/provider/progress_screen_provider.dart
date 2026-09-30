import 'package:flutter/foundation.dart';

import '../../../services/learning_progress_service.dart';

/// Screen-local state for the progress screen: the loaded learning progress
/// and whether a load is in flight.
class ProgressScreenProvider extends ChangeNotifier {
  ProgressScreenProvider(this._loadData);

  final Future<LearningProgressData> Function() _loadData;
  LearningProgressData? _data;
  bool _loading = true;
  bool _disposed = false;

  LearningProgressData? get data => _data;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _loadData();
      if (_disposed) return;
      _data = data;
      _loading = false;
      notifyListeners();
    } catch (error) {
      if (_disposed) return;
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
