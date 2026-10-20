import 'package:flutter/foundation.dart';

import '../../../utils/dob_format.dart';
import '../model/phone_country.dart';

/// Screen-local state for the sign-in screen. Students sign in with name +
/// phone number; teachers switch to phone number + date of birth. Together
/// they decide whether a sign-in can be sent.
class LoginFormProvider extends ChangeNotifier {
  String _phone = '';
  PhoneCountry _country = PhoneCountry.india;
  String _name = '';
  DateTime? _dob;
  bool _isTeacher = false;
  bool _submitted = false;

  DateTime? get dob => _dob;
  bool get isTeacher => _isTeacher;
  PhoneCountry get country => _country;

  /// Whether "Sign In" was tapped: from then on, every field shows what is
  /// still missing or wrong, and updates as it is fixed.
  bool get submitted => _submitted;

  /// The typed number the way the API expects it (see [PhoneCountry.forApi]).
  String get phoneForApi => _country.forApi(_phone.trim());

  /// The typed name, or null for a teacher: only what is on screen is sent.
  String? get nameForApi => _isTeacher ? null : _name.trim();

  /// The picked date as `YYYY-MM-DD` for the API, or null before one is picked.
  String? get dobForApi => _dob == null ? null : formatDobForApi(_dob!);

  /// Shown under the date field once "Sign In" was tapped without a date.
  String? get dobError => _submitted && _isTeacher && _dob == null
      ? 'Please choose your date of birth'
      : null;

  bool get isComplete =>
      _country.acceptsLength(_phone.trim().length) &&
      (_isTeacher ? _dob != null : _name.trim().isNotEmpty);

  void setPhone(String value) {
    if (value == _phone) return;
    _phone = value;
    notifyListeners();
  }

  void setCountry(PhoneCountry value) {
    _country = value;
    notifyListeners();
  }

  void setName(String value) {
    if (value == _name) return;
    _name = value;
    notifyListeners();
  }

  void setDob(DateTime value) {
    _dob = value;
    notifyListeners();
  }

  void markSubmitted() {
    _submitted = true;
    notifyListeners();
  }

  /// Switches between student and teacher sign-in. A picked date is cleared;
  /// a typed name is kept for switching back, but only sent by a student.
  void toggleTeacher() {
    _isTeacher = !_isTeacher;
    _dob = null;
    notifyListeners();
  }
}
