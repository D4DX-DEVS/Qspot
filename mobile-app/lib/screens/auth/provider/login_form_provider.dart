import 'package:flutter/foundation.dart';

import '../../../utils/dob_format.dart';

/// Screen-local state for the sign-in screen. Students sign in with phone
/// number + class; teachers switch to phone number + date of birth. Together
/// they decide whether "Sign In" is ready.
class LoginFormProvider extends ChangeNotifier {
  String _phone = '';
  String? _classNumber;
  DateTime? _dob;
  bool _isTeacher = false;

  String? get classNumber => _classNumber;
  DateTime? get dob => _dob;
  bool get isTeacher => _isTeacher;

  /// The picked date as `YYYY-MM-DD` for the API, or null before one is picked.
  String? get dobForApi => _dob == null ? null : formatDobForApi(_dob!);

  bool get isComplete =>
      _phone.trim().length == 10 &&
      (_isTeacher ? _dob != null : _classNumber != null);

  void setPhone(String value) {
    if (value == _phone) return;
    _phone = value;
    notifyListeners();
  }

  void setClassNumber(String? value) {
    _classNumber = value;
    notifyListeners();
  }

  void setDob(DateTime value) {
    _dob = value;
    notifyListeners();
  }

  /// Switches between student and teacher sign-in. The other way's answer is
  /// cleared, so only the one on screen is ever sent.
  void toggleTeacher() {
    _isTeacher = !_isTeacher;
    _classNumber = null;
    _dob = null;
    notifyListeners();
  }
}
