import 'package:flutter/foundation.dart';

import '../../../services/course_service.dart';

/// Screen-local state for the registration form: typed phone/name (for the
/// completeness check), class, date of birth, consent and course selection.
class RegistrationFormProvider extends ChangeNotifier {
  String _phone = '';
  String _name = '';
  String? _classNumber;
  DateTime? _dob;
  bool _hasConsent = false;
  String _consentBy = 'parent';
  List<CourseModel> _courses = const [];
  final Set<String> _selectedCourseIds = <String>{};
  bool _coursesLoading = true;
  bool _disposed = false;

  String? get classNumber => _classNumber;
  DateTime? get dob => _dob;
  bool get hasConsent => _hasConsent;
  String get consentBy => _consentBy;
  List<CourseModel> get courses => _courses;
  Set<String> get selectedCourseIds => _selectedCourseIds;
  bool get coursesLoading => _coursesLoading;

  bool get isComplete =>
      _phone.trim().length == 10 &&
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

  void setName(String value) {
    _name = value;
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

  String formatDob(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
