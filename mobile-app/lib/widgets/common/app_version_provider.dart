import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Reads the installed app version ("1.2.0", no build number) once, for display.
class AppVersionProvider extends ChangeNotifier {
  AppVersionProvider() {
    _load();
  }

  String _version = '';
  bool _disposed = false;

  String get version => _version;

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (_disposed) return;
      _version = info.version;
      notifyListeners();
    } catch (e) {
      debugPrint('Error reading app version: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
