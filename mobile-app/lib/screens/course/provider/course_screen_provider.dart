import 'package:flutter/foundation.dart';

import '../../../services/course_service.dart';
import '../../../services/video_progress_service.dart';
import '../../../utils/user_friendly_error.dart';
import '../../assignment/model/assignment_model.dart';
import '../../assignment/service/assignment_service.dart';
import '../../grades/model/grade_entry.dart';
import '../../grades/provider/grades_provider.dart';
import '../../grades/service/grades_service.dart';
import '../../subject/model/subject_model.dart';
import '../../subject/provider/subject_provider.dart';
import '../../video/model/video_model.dart';
import '../../video/provider/video_provider.dart';
import '../model/course_syllabus.dart';
import '../model/course_tab.dart';
import '../model/lesson_status.dart';
import '../model/syllabus_lesson.dart';

/// What the syllabus is built from, read fresh each time it is rebuilt.
typedef SyllabusInputs = ({
  List<SubjectModel> subjects,
  List<VideoModel> Function(String subjectId) lessonsFor,
  Map<String, VideoProgressStatus> progress,
});

/// State of one course page: the syllabus with its lock rule, the open
/// chapters, the selected tab and the course's assignments.
class CourseScreenProvider extends ChangeNotifier {
  CourseScreenProvider({
    required this.course,
    required SyllabusInputs Function() readInputs,
    required Listenable inputsChanged,
    Future<List<AssignmentModel>> Function()? fetchAssignments,
    Future<List<GradeEntry>> Function()? fetchGrades,
    Future<void> Function()? refreshProgress,
  }) : _readInputs = readInputs,
       _inputsChanged = inputsChanged,
       _fetchAssignments = fetchAssignments ?? AssignmentService.fetchAll,
       _fetchGrades = fetchGrades ?? GradesService.fetch,
       _refreshProgress = refreshProgress ?? _noRefresh {
    _inputsChanged.addListener(_rebuild);
    _rebuild();
  }

  /// Wired to the app's own video and subject lists.
  factory CourseScreenProvider.forApp({
    required CourseModel course,
    required VideoProvider videos,
    required SubjectProvider subjects,
    Future<List<AssignmentModel>> Function()? fetchAssignments,
    Future<List<GradeEntry>> Function()? fetchGrades,
  }) => CourseScreenProvider(
    course: course,
    inputsChanged: Listenable.merge([videos, subjects]),
    readInputs: () => (
      subjects: subjects.subjects
          .where((subject) => subject.courseId == course.id)
          .toList(),
      lessonsFor: videos.videosForSubject,
      progress: videos.progressByVideo,
    ),
    refreshProgress: videos.loadProgress,
    fetchAssignments: fetchAssignments,
    fetchGrades: fetchGrades,
  );

  final CourseModel course;
  final SyllabusInputs Function() _readInputs;
  final Listenable _inputsChanged;
  final Future<List<AssignmentModel>> Function() _fetchAssignments;
  final Future<List<GradeEntry>> Function() _fetchGrades;
  final Future<void> Function() _refreshProgress;

  CourseSyllabus _syllabus = const CourseSyllabus(chapters: []);
  CourseTab _tab = CourseTab.syllabus;
  final Set<String> _expanded = {};
  bool _expandedSeeded = false;
  List<AssignmentModel> _allAssignments = const [];
  List<GradeEntry> _allGrades = const [];
  bool _assignmentsLoading = true;
  String? _assignmentsError;

  CourseSyllabus get syllabus => _syllabus;
  CourseTab get tab => _tab;
  bool get isLoadingAssignments => _assignmentsLoading;
  String? get assignmentsError => _assignmentsError;
  SyllabusLesson? get nextLesson => _syllabus.next;

  bool isExpanded(String chapterId) => _expanded.contains(chapterId);

  /// This course's assignments: those linked to the course or to one of its
  /// chapters. Work still to do comes first, soonest due first.
  List<AssignmentModel> get assignments {
    final chapterIds = _syllabus.chapters.map((chapter) => chapter.id).toSet();
    final mine = _allAssignments
        .where(
          (item) =>
              item.courseId == course.id ||
              (item.subjectId != null && chapterIds.contains(item.subjectId)),
        )
        .toList();
    mine.sort((a, b) {
      if (a.isSubmitted != b.isSubmitted) return a.isSubmitted ? 1 : -1;
      final aDue = a.dueAt ?? DateTime(2100);
      final bDue = b.dueAt ?? DateTime(2100);
      return aDue.compareTo(bDue);
    });
    return mine;
  }

  int get assignmentsDone =>
      assignments.where((item) => item.isSubmitted).length;

  /// This course's marks, newest first: practice on its lessons, and
  /// assignments linked to the course or one of its chapters.
  List<GradeEntry> get grades {
    final lessonIds = _syllabus.lessons.map((lesson) => lesson.id).toSet();
    final chapterIds = _syllabus.chapters.map((chapter) => chapter.id).toSet();
    return GradesProvider.sortNewestFirst(
      _allGrades.where(
        (entry) =>
            (entry.videoId != null && lessonIds.contains(entry.videoId)) ||
            entry.courseId == course.id ||
            (entry.subjectId != null && chapterIds.contains(entry.subjectId)),
      ),
    );
  }

  /// "Grade average 82%", or null when the course has no marks yet.
  String? get gradeAverageLabel {
    final marks = grades;
    if (marks.isEmpty) return null;
    final total = marks.fold<double>(0, (sum, entry) => sum + entry.percent);
    return 'Grade average ${(total / marks.length).round()}%';
  }

  String get summaryTitle {
    final lessons = _syllabus.summary.lessons;
    if (lessons.total == 0) return 'No lessons yet';
    return '${lessons.completed} of ${lessons.total} lessons';
  }

  String get summaryDetail {
    final total = assignments.length;
    if (total == 0) return 'Lessons open one after another';
    return 'Assignments $assignmentsDone of $total';
  }

  /// Text for the bottom button, or null when there is nothing to carry on
  /// with.
  String? get continueLabel {
    final lesson = nextLesson;
    if (lesson == null) return null;
    final verb = lesson.status == LessonStatus.inProgress
        ? 'Continue'
        : 'Start';
    return '$verb · Chapter ${lesson.chapterNumber}, Lesson ${lesson.number}';
  }

  void selectTab(CourseTab tab) {
    if (tab == _tab) return;
    _tab = tab;
    notifyListeners();
  }

  void toggleChapter(String chapterId) {
    if (!_expanded.remove(chapterId)) _expanded.add(chapterId);
    notifyListeners();
  }

  Future<void> load() async {
    _assignmentsLoading = true;
    _assignmentsError = null;
    notifyListeners();
    await Future.wait([
      () async {
        try {
          _allAssignments = await _fetchAssignments();
        } catch (error) {
          _assignmentsError = userFriendlyError(error);
        }
      }(),
      () async {
        try {
          _allGrades = await _fetchGrades();
        } catch (error) {
          debugPrint('Course grades unavailable: $error');
        }
      }(),
    ]);
    _assignmentsLoading = false;
    notifyListeners();
  }

  /// Reloads the learner's watch state, so a finished lesson unlocks the
  /// next one.
  Future<void> refreshProgress() => _refreshProgress();

  void _rebuild() {
    final inputs = _readInputs();
    _syllabus = CourseSyllabus.build(
      subjects: inputs.subjects,
      lessonsFor: inputs.lessonsFor,
      progress: inputs.progress,
    );
    if (!_expandedSeeded && _syllabus.chapters.isNotEmpty) {
      _expandedSeeded = true;
      final chapterNumber = _syllabus.next?.chapterNumber ?? 1;
      _expanded.add(_syllabus.chapters[chapterNumber - 1].id);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _inputsChanged.removeListener(_rebuild);
    super.dispose();
  }

  static Future<void> _noRefresh() async {}
}
