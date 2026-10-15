import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/assignment/model/assignment_model.dart';
import 'package:qspot/screens/course/model/course_tab.dart';
import 'package:qspot/screens/grades/model/grade_entry.dart';
import 'package:qspot/screens/grades/model/grade_kind.dart';
import 'package:qspot/screens/course/provider/course_screen_provider.dart';
import 'package:qspot/screens/subject/model/subject_model.dart';
import 'package:qspot/screens/video/model/video_model.dart';
import 'package:qspot/services/course_service.dart';
import 'package:qspot/services/video_progress_service.dart';

const _course = CourseModel(id: 'c1', title: 'Tajweed');

/// Stands in for the app's video and subject lists.
class _Source extends ChangeNotifier {
  Map<String, VideoProgressStatus> progress = {};

  void finish(String id) {
    progress = {
      ...progress,
      id: VideoProgressStatus(videoId: id, completed: true),
    };
    notifyListeners();
  }
}

VideoModel _lesson(String id, String chapter, {bool upcoming = false}) =>
    VideoModel(
      id: id,
      caption: '',
      video: 'x',
      title: 'Lesson $id',
      subjectId: chapter,
      isUpcoming: upcoming,
    );

AssignmentModel _assignment(
  String id, {
  String? courseId,
  String? subjectId,
  String status = 'open',
  DateTime? dueAt,
}) => AssignmentModel(
  id: id,
  title: 'Assignment $id',
  courseId: courseId,
  subjectId: subjectId,
  status: status,
  dueAt: dueAt,
);

GradeEntry _grade(
  String title,
  num score, {
  String? videoId,
  String? courseId,
  String? subjectId,
  DateTime? date,
}) => GradeEntry(
  kind: videoId != null ? GradeKind.lessonPractice : GradeKind.assignment,
  title: title,
  score: score,
  outOf: 10,
  videoId: videoId,
  courseId: courseId,
  subjectId: subjectId,
  date: date,
);

CourseScreenProvider _provider(
  _Source source, {
  List<AssignmentModel> assignments = const [],
  List<GradeEntry> grades = const [],
  Future<void> Function()? refresh,
  bool upcomingLast = false,
}) {
  final lessons = {
    's1': [_lesson('a', 's1')],
    's2': [
      _lesson('b', 's2'),
      _lesson('c', 's2'),
      if (upcomingLast) _lesson('soon', 's2', upcoming: true),
    ],
  };
  return CourseScreenProvider(
    course: _course,
    inputsChanged: source,
    readInputs: () => (
      subjects: [
        SubjectModel(id: 's1', subject: 'one', order: 1, courseId: 'c1'),
        SubjectModel(id: 's2', subject: 'two', order: 2, courseId: 'c1'),
      ],
      lessonsFor: (id) => lessons[id] ?? const [],
      progress: source.progress,
    ),
    fetchAssignments: () async => assignments,
    fetchGrades: () async => grades,
    refreshProgress: refresh,
  );
}

void main() {
  test('opens the chapter with the next lesson first', () {
    final source = _Source()
      ..progress = {'a': VideoProgressStatus(videoId: 'a', completed: true)};
    final provider = _provider(source);

    expect(provider.isExpanded('s1'), isFalse);
    expect(provider.isExpanded('s2'), isTrue);
  });

  test('opens the first chapter for a learner who has not started', () {
    final provider = _provider(_Source());

    expect(provider.isExpanded('s1'), isTrue);
    expect(provider.isExpanded('s2'), isFalse);
  });

  test('a chapter can be opened and closed', () {
    final provider = _provider(_Source());

    provider.toggleChapter('s2');
    expect(provider.isExpanded('s2'), isTrue);
    provider.toggleChapter('s2');
    expect(provider.isExpanded('s2'), isFalse);
  });

  test('choosing a tab changes it once', () {
    final provider = _provider(_Source());
    var notified = 0;
    provider.addListener(() => notified++);

    provider.selectTab(CourseTab.about);
    provider.selectTab(CourseTab.about);

    expect(provider.tab, CourseTab.about);
    expect(notified, 1);
  });

  test('finishing a lesson opens the next and moves the button on', () {
    final source = _Source();
    final provider = _provider(source);
    expect(provider.continueLabel, 'Start · Chapter 1, Lesson 1');

    source.finish('a');

    expect(provider.continueLabel, 'Start · Chapter 2, Lesson 1');
    expect(provider.summaryTitle, '1 of 3 lessons');
  });

  test('a lesson being watched reads Continue', () {
    final source = _Source()
      ..progress = {
        'a': VideoProgressStatus(videoId: 'a', completed: true),
        'b': const VideoProgressStatus(videoId: 'b', positionSeconds: 60),
      };

    expect(_provider(source).continueLabel, 'Continue · Chapter 2, Lesson 1');
  });

  test('no button once everything released is finished', () {
    final source = _Source();
    final provider = _provider(source, upcomingLast: true);
    source.finish('a');
    source.finish('b');
    source.finish('c');

    expect(provider.continueLabel, isNull);
    expect(provider.nextLesson, isNull);
  });

  test('progress is reloaded after a lesson is watched', () async {
    var reloads = 0;
    final provider = _provider(_Source(), refresh: () async => reloads++);

    await provider.refreshProgress();

    expect(reloads, 1);
  });

  group('assignments', () {
    test('keeps this course and its chapters, to do first', () async {
      final provider = _provider(
        _Source(),
        assignments: [
          _assignment('other', courseId: 'c9', subjectId: 's9'),
          _assignment('done', courseId: 'c1', status: 'submitted'),
          _assignment(
            'byChapter',
            subjectId: 's2',
            dueAt: DateTime(2030, 2, 1),
          ),
          _assignment('byCourse', courseId: 'c1', dueAt: DateTime(2030, 1, 1)),
          _assignment('loose'),
        ],
      );

      await provider.load();

      expect(provider.assignments.map((a) => a.id), [
        'byCourse',
        'byChapter',
        'done',
      ]);
      expect(provider.assignmentsDone, 1);
      expect(provider.summaryDetail, 'Assignments 1 of 3');
      expect(provider.isLoadingAssignments, isFalse);
    });

    test('without any, the summary says there are none yet', () async {
      final provider = _provider(_Source());

      await provider.load();

      expect(provider.summaryDetail, 'No assignments yet');
    });

    test('a failed load leaves the syllabus usable', () async {
      final provider = CourseScreenProvider(
        course: _course,
        inputsChanged: _Source(),
        readInputs: () => (
          subjects: <SubjectModel>[],
          lessonsFor: (_) => <VideoModel>[],
          progress: <String, VideoProgressStatus>{},
        ),
        fetchAssignments: () async => throw Exception('offline'),
        fetchGrades: () async => const [],
      );

      await provider.load();

      expect(provider.assignmentsError, isNotNull);
      expect(provider.assignments, isEmpty);
      expect(provider.isLoadingAssignments, isFalse);
    });
  });

  group('grades', () {
    test('keeps this course\'s marks, newest first', () async {
      final provider = _provider(
        _Source(),
        grades: [
          _grade('Other course', 9, videoId: 'elsewhere'),
          _grade('Practice on a', 6, videoId: 'a', date: DateTime(2026, 10, 1)),
          _grade(
            'Work for the course',
            8,
            courseId: 'c1',
            date: DateTime(2026, 10, 5),
          ),
          _grade(
            'Work for a chapter',
            7,
            subjectId: 's2',
            date: DateTime(2026, 10, 3),
          ),
          _grade('Unlinked work', 10),
        ],
      );

      await provider.load();

      expect(provider.grades.map((g) => g.title), [
        'Work for the course',
        'Work for a chapter',
        'Practice on a',
      ]);
    });

    test('shows the grade average, or nothing without marks', () async {
      final withMarks = _provider(
        _Source(),
        grades: [
          _grade('One', 6, videoId: 'a'),
          _grade('Two', 9, courseId: 'c1'),
        ],
      );
      final without = _provider(_Source());

      expect(withMarks.gradeAverageLabel, isNull);
      await withMarks.load();
      await without.load();

      // 60% and 90% make 75%.
      expect(withMarks.gradeAverageLabel, 'Grade average 75%');
      expect(without.gradeAverageLabel, isNull);
    });

    test(
      'marks that fail to load leave the rest of the page working',
      () async {
        final provider = CourseScreenProvider(
          course: _course,
          inputsChanged: _Source(),
          readInputs: () => (
            subjects: <SubjectModel>[],
            lessonsFor: (_) => <VideoModel>[],
            progress: <String, VideoProgressStatus>{},
          ),
          fetchAssignments: () async => [_assignment('a1', courseId: 'c1')],
          fetchGrades: () async => throw Exception('offline'),
        );

        await provider.load();

        expect(provider.grades, isEmpty);
        expect(provider.assignments, hasLength(1));
        expect(provider.isLoadingAssignments, isFalse);
      },
    );
  });

  test('stops listening once disposed', () {
    final source = _Source();
    final provider = _provider(source);

    provider.dispose();

    // A disposed provider that still listened would throw when it rebuilt.
    expect(() => source.finish('a'), returnsNormally);
  });
}
