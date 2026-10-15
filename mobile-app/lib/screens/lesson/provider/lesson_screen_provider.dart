import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../services/course_service.dart';
import '../../../services/video_progress_service.dart';
import '../../bookmark/provider/bookmark_provider.dart';
import '../../course/model/course_syllabus.dart';
import '../../course/model/lesson_status.dart';
import '../../course/model/syllabus_chapter.dart';
import '../../course/model/syllabus_lesson.dart';
import '../../subject/model/subject_model.dart';
import '../../subject/provider/subject_provider.dart';
import '../../video/model/video_model.dart';
import '../../video/provider/video_provider.dart';
import '../model/lesson_tab.dart';

/// What the lesson page is built from, read fresh each time it rebuilds.
typedef LessonInputs = ({
  List<SubjectModel> subjects,
  List<CourseModel> courses,
  List<VideoModel> Function(String subjectId) lessonsFor,
  Map<String, VideoProgressStatus> progress,
});

/// State of one lesson page: where the lesson sits in its course, whether the
/// learner may play it, and the lessons before and after it.
class LessonScreenProvider extends ChangeNotifier {
  LessonScreenProvider({
    required this.video,
    required LessonInputs Function() readInputs,
    required Listenable inputsChanged,
    required bool Function() readSaved,
    required Future<bool> Function() toggleSavedState,
    Future<void> Function()? refreshProgress,
  }) : _readInputs = readInputs,
       _inputsChanged = inputsChanged,
       _readSaved = readSaved,
       _toggleSavedState = toggleSavedState,
       _refreshProgress = refreshProgress ?? _noRefresh {
    _inputsChanged.addListener(_rebuild);
    _rebuild();
  }

  /// Wired to the app's own video, subject and bookmark lists.
  factory LessonScreenProvider.forApp({
    required VideoModel video,
    required VideoProvider videos,
    required SubjectProvider subjects,
    required BookmarkProvider bookmarks,
  }) => LessonScreenProvider(
    video: video,
    inputsChanged: Listenable.merge([videos, subjects, bookmarks]),
    readInputs: () => (
      subjects: subjects.subjects,
      courses: subjects.courses,
      lessonsFor: videos.videosForSubject,
      progress: videos.progressByVideo,
    ),
    readSaved: () => bookmarks.isBookmarkedSync(video.id),
    toggleSavedState: () => bookmarks.toggleBookmark(video),
    refreshProgress: videos.loadProgress,
  );

  final VideoModel video;
  final LessonInputs Function() _readInputs;
  final Listenable _inputsChanged;
  final bool Function() _readSaved;
  final Future<bool> Function() _toggleSavedState;
  final Future<void> Function() _refreshProgress;

  CourseSyllabus _syllabus = const CourseSyllabus(chapters: []);
  String _courseTitle = '';
  VideoProgressStatus? _watch;
  LessonTab _tab = LessonTab.learn;

  CourseSyllabus get syllabus => _syllabus;
  LessonTab get tab => _tab;
  bool get isSaved => _readSaved();

  /// This lesson's place in its course, or null when the course is not known.
  SyllabusLesson? get lesson => _syllabus.lessonFor(video.id);
  SyllabusChapter? get chapter => _syllabus.chapterOf(video.id);
  SyllabusLesson? get previous => _syllabus.previousOf(video.id);
  SyllabusLesson? get next => _syllabus.nextOf(video.id);

  String? get positionLabel {
    final current = lesson;
    final inChapter = chapter;
    if (current == null || inChapter == null) return null;
    return 'Lesson ${current.number} of ${inChapter.lessons.length}';
  }

  /// "Tajweed · Chapter 2", with whatever part is known.
  String get crumb {
    final parts = [
      if (_courseTitle.isNotEmpty) _courseTitle,
      if (chapter != null) 'Chapter ${chapter!.number}',
    ];
    return parts.isEmpty ? chapterTitle : parts.join(' · ');
  }

  String get chapterTitle => chapter?.title ?? video.subjectName ?? '';

  /// "Madd Rules · 11 Oct 2026".
  String get subtitle {
    final date = video.date;
    return [
      chapterTitle,
      if (date != null) DateFormat('d MMM yyyy').format(date.toLocal()),
    ].where((part) => part.isNotEmpty).join(' · ');
  }

  bool get isCompleted => _watch?.completed == true;
  double get watchedFraction => _watch?.percent ?? 0;

  /// Where the learner stands, or null when the course is not known.
  LessonStatus? get status => lesson?.status;

  /// The lesson may be played now: released, in its course or not.
  bool get canPlay => lesson?.isOpenable ?? !video.isUpcoming;

  String? get playBlockedMessage =>
      lesson?.blockedMessage ??
      (video.isUpcoming ? 'This lesson has not opened yet.' : null);

  /// How far the learner has watched, e.g. "6:20".
  String get positionText => _clock(_watch?.positionSeconds ?? 0);

  /// The lesson's length, e.g. "14:00", or null when it is not known.
  String? get durationText {
    final seconds = video.durationSeconds > 0
        ? video.durationSeconds
        : (_watch?.durationSeconds ?? 0);
    return seconds > 0 ? _clock(seconds) : null;
  }

  String get playLabel {
    if (!canPlay) return playBlockedMessage ?? 'Not open yet';
    if (isCompleted) return 'Watch again';
    final seconds = _watch?.positionSeconds ?? 0;
    if (seconds > 0) return 'Resume at ${_clock(seconds)}';
    return 'Watch lesson';
  }

  bool get practiceUnlocked => isCompleted;

  int get questionCount =>
      math.max(video.questionCount, _watch?.questionCount ?? 0);

  bool get canOpenNext => next?.isOpenable == true;

  /// Why the next lesson is closed, or null when it is open or absent.
  String? get nextHint {
    final following = next;
    if (following == null || following.isOpenable) return null;
    return 'The next lesson has not opened yet.';
  }

  void selectTab(LessonTab tab) {
    if (tab == _tab) return;
    _tab = tab;
    notifyListeners();
  }

  /// Saves or unsaves the lesson. Returns whether it is saved now, or null
  /// when that could not be done.
  Future<bool?> toggleSaved() async {
    final changed = await _toggleSavedState();
    notifyListeners();
    return changed ? isSaved : null;
  }

  /// Reloads the learner's watch state, so a finished lesson opens Practice.
  Future<void> refreshProgress() => _refreshProgress();

  void _rebuild() {
    final inputs = _readInputs();
    _syllabus = CourseSyllabus.forChapter(
      subjectId: video.subjectId ?? '',
      subjects: inputs.subjects,
      lessonsFor: inputs.lessonsFor,
      progress: inputs.progress,
    );
    _watch = inputs.progress[video.id];
    final courseId = inputs.subjects
        .where((subject) => subject.id == video.subjectId)
        .firstOrNull
        ?.courseId;
    _courseTitle =
        inputs.courses
            .where((course) => course.id == courseId)
            .firstOrNull
            ?.title ??
        '';
    notifyListeners();
  }

  @override
  void dispose() {
    _inputsChanged.removeListener(_rebuild);
    super.dispose();
  }

  static Future<void> _noRefresh() async {}

  static String _clock(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
