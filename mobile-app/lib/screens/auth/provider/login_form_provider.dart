import 'package:flutter/foundation.dart';

import '../../../utils/dob_format.dart';

/// Screen-local state for the sign-in screen: the typed phone number and the
/// picked date of birth, which together decide whether "Sign In" is ready.
class LoginFormProvider extends ChangeNotifier {
  String _phone = '';
  DateTime? _dob;

  DateTime? get dob => _dob;

  /// The picked date as `YYYY-MM-DD` for the API, or null before one is picked.
  String? get dobForApi => _dob == null ? null : formatDobForApi(_dob!);

  bool get isComplete => _phone.trim().length == 10 && _dob != null;

  void setPhone(String value) {
    if (value == _phone) return;
    _phone = value;
    notifyListeners();
  }

  void setDob(DateTime value) {
    _dob = value;
    notifyListeners();
  }
}
