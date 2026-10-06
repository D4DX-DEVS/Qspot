import 'package:flutter/foundation.dart';

import '../model/subject_model.dart';
import '../../../services/api_client.dart';
import '../../../services/course_service.dart';
import '../../../utils/user_friendly_error.dart';
import '../../../services/common/storage_service.dart';

enum SubjectLoadingState { idle, loading, loaded, error }

/// One course with the subjects that belong to it, for the grouped
/// Subjects tab (R1).
class CourseSubjects {
  final CourseModel course;
  final List<SubjectModel> subjects;

  const CourseSubjects({required this.course, required this.subjects});
}

class SubjectProvider with ChangeNotifier {
  // State variables
  SubjectLoadingState _loadingState = SubjectLoadingState.idle;
  String _errorMessage = '';

  // Subject data
  List<SubjectModel> _subjects = [];
  List<CourseModel> _courses = [];
  SubjectModel? _selectedSubject;

  // Getters
  SubjectLoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;
  List<SubjectModel> get subjects => _subjects;
  List<CourseModel> get courses => _courses;
  SubjectModel? get selectedSubject => _selectedSubject;

  bool get isLoading => _loadingState == SubjectLoadingState.loading;
  bool get hasError => _loadingState == SubjectLoadingState.error;
  bool get isEmpty =>
      _subjects.isEmpty && _loadingState == SubjectLoadingState.loaded;

  /// Subjects grouped by the course they belong to (fetches
  /// `/api/courses` + `/api/subjects`, groups client-side — R1). Subjects
  /// with no `courseId` are collected under a synthetic "Other" bucket only
  /// when there is at least one, so courses without loose subjects don't
  /// show an empty group.
  List<CourseSubjects> get groupedByCourse {
    final byCourse = <String, List<SubjectModel>>{};
    final orphaned = <SubjectModel>[];
    for (final subject in _subjects) {
      final courseId = subject.courseId;
      if (courseId == null || courseId.isEmpty) {
        orphaned.add(subject);
        continue;
      }
      byCourse.putIfAbsent(courseId, () => []).add(subject);
    }

    final groups = <CourseSubjects>[
      for (final course in _courses)
        if ((byCourse[course.id] ?? const []).isNotEmpty)
          CourseSubjects(
            course: course,
            subjects: byCourse[course.id]!
              ..sort((a, b) => a.order.compareTo(b.order)),
          ),
    ];

    if (orphaned.isNotEmpty) {
      groups.add(
        CourseSubjects(
          course: const CourseModel(id: '', title: 'Other Subjects'),
          subjects: orphaned..sort((a, b) => a.order.compareTo(b.order)),
        ),
      );
    }

    return groups;
  }

  // Initialize and load all subject data
  Future<void> initialize() async {
    await _setLoadingState(SubjectLoadingState.loading);
    await _loadFromCache();

    try {
      await fetchSubjects();
      await _setLoadingState(SubjectLoadingState.loaded);
    } catch (e) {
      if (_subjects.isNotEmpty) {
        await _useCachedData();
      } else {
        await _handleError(userFriendlyError(e));
      }
    }
  }

  // Fetch all subjects + the courses they belong to, in parallel.
  Future<void> fetchSubjects() async {
    try {
      final results = await Future.wait([
        ApiClient.get('/api/subjects'),
        CourseService.fetchActive(throwOnError: true),
      ]);

      final subjectsBody = results[0];
      final List<dynamic> subjectsJson = subjectsBody is List
          ? subjectsBody
          : const [];
      final subjects = subjectsJson
          .whereType<Map>()
          .map((json) => SubjectModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      subjects.sort((a, b) => a.order.compareTo(b.order));

      _subjects = subjects;
      _courses = results[1] as List<CourseModel>;
      await StorageService.cacheSubjects(_subjects);
      await StorageService.cacheCourses(
        _courses.map((course) => course.toJson()).toList(),
      );
      debugPrint(
        '📚 [SUBJECTS] Loaded ${_subjects.length} subjects, ${_courses.length} courses',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('📚 [SUBJECTS] Error: $e');
      rethrow;
    }
  }

  // Set selected subject
  void setSelectedSubject(SubjectModel? subject) {
    _selectedSubject = subject;
    notifyListeners();
  }

  // Get subject by ID from local list
  SubjectModel? getSubjectById(String id) {
    try {
      return _subjects.firstWhere((subject) => subject.id == id);
    } catch (_) {
      return null;
    }
  }

  // Search subjects by name
  List<SubjectModel> searchSubjects(String query) {
    if (query.isEmpty) return _subjects;

    final lowerQuery = query.toLowerCase();
    return _subjects.where((subject) {
      return subject.subject.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Refresh subjects data
  Future<void> refresh() async {
    await _setLoadingState(SubjectLoadingState.loading);

    try {
      await fetchSubjects();
      await _setLoadingState(SubjectLoadingState.loaded);
    } catch (e) {
      if (_subjects.isNotEmpty) {
        await _useCachedData();
      } else {
        await _handleError(userFriendlyError(e));
      }
    }
  }

  // Private helper methods
  Future<void> _setLoadingState(SubjectLoadingState state) async {
    _loadingState = state;
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> _handleError(String message) async {
    _loadingState = SubjectLoadingState.error;
    _errorMessage = message;
    debugPrint('SubjectProvider Error: $message');
    notifyListeners();
  }

  Future<void> _loadFromCache() async {
    final cachedSubjects = await StorageService.getCachedSubjects();
    if (cachedSubjects.isEmpty) return;
    final cachedCourses = (await StorageService.getCachedCourses())
        .map(CourseModel.fromJson)
        .where((course) => course.title.isNotEmpty)
        .toList();
    _subjects = cachedSubjects;
    _courses = cachedCourses;
    notifyListeners();
  }

  Future<void> _useCachedData() async {
    _loadingState = SubjectLoadingState.loaded;
    _errorMessage =
        'You’re offline. Showing saved chapters. Reconnect to sync updates.';
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _subjects.clear();
    _courses.clear();
    _selectedSubject = null;
    _loadingState = SubjectLoadingState.idle;
    _errorMessage = '';
    notifyListeners();
  }
}
