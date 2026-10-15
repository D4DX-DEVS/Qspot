import 'package:flutter/foundation.dart';

import '../../../services/api_client.dart';
import '../../../utils/user_friendly_error.dart';

/// Screen-local state for the faculty workspace: the questions, lessons and
/// assignments lists plus the loading / error flags around fetching them.
class FacultyHomeScreenProvider extends ChangeNotifier {
  List<dynamic> _questions = const [];
  List<dynamic> _content = const [];
  List<dynamic> _assignments = const [];
  bool _loading = true;
  String? _error;
  bool _disposed = false;

  List<dynamic> get questions => _questions;
  List<dynamic> get content => _content;
  List<dynamic> get assignments => _assignments;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    if (_disposed) {
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        ApiClient.get('/api/faculty/questions'),
        ApiClient.get('/api/faculty/content'),
        ApiClient.get('/api/faculty/assignments'),
      ]);
      if (_disposed) {
        return;
      }
      _questions = results[0] is List ? results[0] : const [];
      _content = results[1] is List ? results[1] : const [];
      _assignments = results[2] is List ? results[2] : const [];
      _loading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      if (_disposed) {
        return;
      }
      _error = userFriendlyError(e);
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
