import 'package:flutter/foundation.dart';

import '../../../services/api_client.dart';
import '../../../services/course_service.dart';
import '../../../utils/user_friendly_error.dart';
import '../../auth/model/user_model.dart';

/// State for the "choose your courses" sheet: the courses on offer, which of
/// them the learner has ticked, and saving the choice to their account.
class CourseSelectionProvider extends ChangeNotifier {
  CourseSelectionProvider({
    required this.applyUser,
    Set<String> initialSelection = const {},
    Future<List<CourseModel>> Function()? fetchCourses,
    Future<UserModel> Function(List<String> courseIds)? saveCourses,
  }) : _selected = {...initialSelection},
       _fetchCourses = fetchCourses ?? _fetchAllActive,
       _saveCourses = saveCourses ?? _saveToAccount;

  /// Called with the saved profile so the app uses the new course list at once.
  final Future<void> Function(UserModel user) applyUser;
  final Future<List<CourseModel>> Function() _fetchCourses;
  final Future<UserModel> Function(List<String> courseIds) _saveCourses;

  final Set<String> _selected;
  List<CourseModel> _courses = const [];
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;

  List<CourseModel> get courses => _courses;
  Set<String> get selected => Set.unmodifiable(_selected);
  bool get isLoading => _loading;
  bool get isSaving => _saving;
  String? get errorMessage => _errorMessage;

  /// At least one course must be ticked: saving none would leave the learner
  /// with an empty app.
  bool get canSave => !_loading && !_saving && _selected.isNotEmpty;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _courses = await _fetchCourses();
    } catch (error) {
      _errorMessage = userFriendlyError(error);
    }
    _loading = false;
    notifyListeners();
  }

  void toggle(String courseId, bool selected) {
    if (selected) {
      _selected.add(courseId);
    } else {
      _selected.remove(courseId);
    }
    notifyListeners();
  }

  /// Saves the ticked courses. Returns true when the account was updated.
  Future<bool> save() async {
    if (!canSave) return false;
    _saving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = await _saveCourses(_selected.toList());
      await applyUser(user);
      _saving = false;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error is ApiException
          ? error.message
          : "We couldn't update your courses. Please try again.";
      _saving = false;
      notifyListeners();
      return false;
    }
  }

  static Future<List<CourseModel>> _fetchAllActive() =>
      CourseService.fetchActive(forSelection: true, throwOnError: true);

  static Future<UserModel> _saveToAccount(List<String> courseIds) async {
    final response = await ApiClient.put(
      '/api/user/me',
      body: {'courseIds': courseIds},
    );
    final user = response is Map ? response['user'] : null;
    if (user is! Map) {
      throw const FormatException('The server did not return your profile');
    }
    return UserModel.fromJson(Map<String, dynamic>.from(user));
  }
}
