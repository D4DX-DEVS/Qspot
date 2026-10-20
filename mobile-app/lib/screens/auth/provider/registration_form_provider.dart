import 'package:flutter/foundation.dart';

import '../../../services/course_service.dart';
import '../model/phone_country.dart';

/// Screen-local state for the registration form: typed phone (and its
/// country), name and class (all needed for the completeness check), consent
/// and course selection.
class RegistrationFormProvider extends ChangeNotifier {
  String _phone = '';
  PhoneCountry _country = PhoneCountry.india;
  String _name = '';
  String? _classNumber;
  bool _hasConsent = false;
  String _consentBy = 'parent';
  List<CourseModel> _courses = const [];
  final Set<String> _selectedCourseIds = <String>{};
  bool _coursesLoading = true;
  bool _disposed = false;

  String? get classNumber => _classNumber;
  PhoneCountry get country => _country;

  /// The typed number the way the API expects it (see [PhoneCountry.forApi]).
  String get phoneForApi => _country.forApi(_phone.trim());
  bool get hasConsent => _hasConsent;
  String get consentBy => _consentBy;
  List<CourseModel> get courses => _courses;
  Set<String> get selectedCourseIds => _selectedCourseIds;
  bool get coursesLoading => _coursesLoading;

  bool get isComplete =>
      _country.acceptsLength(_phone.trim().length) &&
      _name.trim().length >= 3 &&
      _classNumber != null;

  Future<void> loadCourses() async {
    final courses = await CourseService.fetchActive();
    if (_disposed) return;
    _courses = courses;
    _coursesLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void setPhone(String value) {
    _phone = value;
    notifyListeners();
  }

  void setCountry(PhoneCountry value) {
    _country = value;
    notifyListeners();
  }

  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void setClassNumber(String? value) {
    _classNumber = value;
    notifyListeners();
  }

  void setHasConsent(bool value) {
    _hasConsent = value;
    notifyListeners();
  }

  void setConsentBy(String value) {
    _consentBy = value;
    notifyListeners();
  }

  void toggleCourse(String id, bool selected) {
    if (selected) {
      _selectedCourseIds.add(id);
    } else {
      _selectedCourseIds.remove(id);
    }
    notifyListeners();
  }
}
