import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../schedule/service/alarm_service.dart';

/// Screen-local state for the settings screen: the daily reminder switch and
/// time, the loading flag while they are read from storage, and the app
/// version string shown in the info card.
class SettingsScreenProvider extends ChangeNotifier {
  bool _alarmEnabled = false;
  int _alarmHour = 18;
  int _alarmMinute = 50;
  bool _isLoading = true;
  String _appVersion = '';
  bool _disposed = false;

  bool get alarmEnabled => _alarmEnabled;
  int get alarmHour => _alarmHour;
  int get alarmMinute => _alarmMinute;
  bool get isLoading => _isLoading;
  String get appVersion => _appVersion;

  Future<void> loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (_disposed) {
      return;
    }
    _appVersion = info.version;
    notifyListeners();
  }

  Future<void> loadAlarmSettings(AlarmService alarmService) async {
    try {
      final isEnabled = await alarmService.isAlarmEnabled();
      final time = await alarmService.getSavedAlarmTime();
      if (_disposed) {
        return;
      }
      _alarmEnabled = isEnabled;
      _alarmHour = time['hour']!;
      _alarmMinute = time['minute']!;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading alarm settings: $e');
      if (_disposed) {
        return;
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  void setAlarmEnabled(bool value) {
    if (_disposed) {
      return;
    }
    _alarmEnabled = value;
    notifyListeners();
  }

  void setAlarmTime(int hour, int minute) {
    if (_disposed) {
      return;
    }
    _alarmHour = hour;
    _alarmMinute = minute;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
