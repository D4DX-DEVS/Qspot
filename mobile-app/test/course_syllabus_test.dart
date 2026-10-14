import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/course/model/course_lesson_summary.dart';
import 'package:qspot/screens/course/model/course_syllabus.dart';
import 'package:qspot/screens/course/model/lesson_status.dart';
import 'package:qspot/screens/subject/model/chapter_progress.dart';
import 'package:qspot/screens/subject/model/subject_model.dart';
import 'package:qspot/screens/video/model/video_model.dart';
import 'package:qspot/services/video_progress_service.dart';

SubjectModel _chapter(String id, int order) =>
    SubjectModel(id: id, subject: 'chapter $id', order: order, courseId: 'c1');

VideoModel _lesson(String id, String chapter, {bool upcoming = false}) =>
    VideoModel(
      id: id,
      caption: '',
      video: 'x',
      title: 'Lesson $id',
      subjectId: chapter,
      isUpcoming: upcoming,
      durationSeconds: 600,
    );

VideoProgressStatus _done(String id) =>
    VideoProgressStatus(videoId: id, completed: true, positionSeconds: 600);

VideoProgressStatus _begun(String id) => VideoProgressStatus(
  videoId: id,
  positionSeconds: 120,
  durationSeconds: 600,
);

CourseSyllabus _build(
  Map<String, List<VideoModel>> lessons, {
  Map<String, VideoProgressStatus> progress = const {},
  List<SubjectModel>? chapters,
}) => CourseSyllabus.build(
  subjects:
      chapters ??
      [for (var i = 0; i < lessons.length; i++) _chapter('s${i + 1}', i + 1)],
  lessonsFor: (id) => lessons[id] ?? const [],
  progress: progress,
);

List<LessonStatus> _statuses(CourseSyllabus syllabus) => [
  for (final lesson in syllabus.lessons) lesson.status,
];

void main() {
  group('lock rule', () {
    final lessons = {
      's1': [_lesson('a', 's1'), _lesson('b', 's1'), _lesson('c', 's1')],
    };

    test('only the first lesson is open to begin with', () {
      final syllabus = _build(lessons);

      expect(_statuses(syllabus), [
        LessonStatus.upNext,
        LessonStatus.locked,
        LessonStatus.locked,
      ]);
    });

    test('finishing a lesson opens the next one', () {
      final syllabus = _build(lessons, progress: {'a': _done('a')});

      expect(_statuses(syllabus), [
        LessonStatus.completed,
        LessonStatus.upNext,
        LessonStatus.locked,
      ]);
    });

    test('a lesson being watched is where the learner left off', () {
      final syllabus = _build(
        lessons,
        progress: {'a': _done('a'), 'b': _begun('b')},
      );

      expect(_statuses(syllabus), [
        LessonStatus.completed,
        LessonStatus.inProgress,
        LessonStatus.locked,
      ]);
      expect(syllabus.next?.id, 'b');
    });

    test('a locked lesson says what to finish first', () {
      final syllabus = _build(lessons);

      expect(
        syllabus.lessons.elementAt(2).lockHint,
        'Finish "Lesson a" first.',
      );
    });

    test('skipping ahead does not open the lessons in between', () {
      final syllabus = _build(lessons, progress: {'c': _done('c')});

      // Lesson c was finished earlier, so it stays open, but b is still shut.
      expect(_statuses(syllabus), [
        LessonStatus.upNext,
        LessonStatus.locked,
        LessonStatus.completed,
      ]);
    });

    test('everything finished leaves nothing to carry on with', () {
      final syllabus = _build(
        lessons,
        progress: {'a': _done('a'), 'b': _done('b'), 'c': _done('c')},
      );

      expect(syllabus.next, isNull);
      expect(syllabus.lessons.every((l) => l.isOpenable), isTrue);
    });

    test('the lock carries across chapters', () {
      final twoChapters = {
        's1': [_lesson('a', 's1')],
        's2': [_lesson('b', 's2'), _lesson('c', 's2')],
      };

      final started = _build(twoChapters);
      expect(started.chapters[1].isLocked, isTrue);

      final firstDone = _build(twoChapters, progress: {'a': _done('a')});
      expect(firstDone.chapters[1].isLocked, isFalse);
      expect(_statuses(firstDone), [
        LessonStatus.completed,
        LessonStatus.upNext,
        LessonStatus.locked,
      ]);
      expect(firstDone.next?.chapterNumber, 2);
      expect(firstDone.next?.number, 1);
    });

    test('a lesson that opens later blocks the ones after it', () {
      final syllabus = _build(
        {
          's1': [
            _lesson('a', 's1'),
            _lesson('soon', 's1', upcoming: true),
            _lesson('c', 's1'),
          ],
        },
        progress: {'a': _done('a')},
      );

      expect(_statuses(syllabus), [
        LessonStatus.completed,
        LessonStatus.upcoming,
        LessonStatus.locked,
      ]);
      expect(syllabus.next, isNull);
    });
  });

  group('layout and counts', () {
    test('chapters follow their order and lessons are numbered', () {
      final syllabus = _build(
        {
          's1': [_lesson('a', 's1'), _lesson('b', 's1')],
          's2': [_lesson('c', 's2')],
        },
        chapters: [_chapter('s2', 2), _chapter('s1', 1)],
      );

      expect(syllabus.chapters.map((c) => c.id), ['s1', 's2']);
      expect(syllabus.chapters.map((c) => c.number), [1, 2]);
      expect(syllabus.lessons.map((l) => '${l.chapterNumber}.${l.number}'), [
        '1.1',
        '1.2',
        '2.1',
      ]);
    });

    test('counts skip lessons that open later', () {
      final syllabus = _build(
        {
          's1': [
            _lesson('a', 's1'),
            _lesson('b', 's1'),
            _lesson('soon', 's1', upcoming: true),
          ],
        },
        progress: {'a': _done('a'), 'b': _begun('b')},
      );

      final counts = syllabus.chapters.single.progress;
      expect(counts.total, 2);
      expect(counts.completed, 1);
      expect(counts.started, 1);
    });

    test('a chapter with no lessons is empty, not locked', () {
      final syllabus = _build({'s1': const []});

      expect(syllabus.isEmpty, isTrue);
      expect(syllabus.chapters.single.isLocked, isFalse);
    });

    test('only open lessons can be played, and a closed one says why', () {
      final syllabus = _build({
        's1': [
          _lesson('a', 's1'),
          _lesson('b', 's1'),
          _lesson('soon', 's1', upcoming: true),
        ],
      });

      final lessons = syllabus.lessons.toList();
      expect(lessons.map((l) => l.isOpenable), [true, false, false]);
      expect(lessons[0].blockedMessage, isNull);
      expect(lessons[1].blockedMessage, 'Finish "Lesson a" first.');
      expect(lessons[2].blockedMessage, 'This lesson has not opened yet.');
    });
  });

  group('finding a lesson', () {
    final twoChapters = {
      's1': [_lesson('a', 's1'), _lesson('b', 's1')],
      's2': [_lesson('c', 's2')],
    };

    test('knows the lessons before and after, across chapters', () {
      final syllabus = _build(twoChapters);

      expect(syllabus.previousOf('a'), isNull);
      expect(syllabus.nextOf('a')?.id, 'b');
      expect(syllabus.previousOf('c')?.id, 'b');
      expect(syllabus.nextOf('c'), isNull);
      expect(syllabus.previousOf('nope'), isNull);
      expect(syllabus.nextOf('nope'), isNull);
    });

    test('finds a lesson and its chapter by video id', () {
      final syllabus = _build(twoChapters);

      expect(syllabus.lessonFor('c')?.chapterNumber, 2);
      expect(syllabus.chapterOf('c')?.id, 's2');
      expect(syllabus.lessonFor('nope'), isNull);
      expect(syllabus.chapterOf('nope'), isNull);
    });

    test('a chapter in a course is laid out with the rest of the course', () {
      final subjects = [
        SubjectModel(id: 's1', subject: 'one', order: 1, courseId: 'c1'),
        SubjectModel(id: 's2', subject: 'two', order: 2, courseId: 'c1'),
        SubjectModel(id: 's3', subject: 'other', order: 1, courseId: 'c2'),
      ];
      final syllabus = CourseSyllabus.forChapter(
        subjectId: 's2',
        subjects: subjects,
        lessonsFor: (id) => {
          's1': [_lesson('a', 's1')],
          's2': [_lesson('b', 's2')],
          's3': [_lesson('z', 's3')],
        }[id]!,
        progress: const {},
      );

      expect(syllabus.chapters.map((c) => c.id), ['s1', 's2']);
      expect(syllabus.lessonFor('z'), isNull);
      // Lesson b is locked behind lesson a, as on the Course page.
      expect(syllabus.lessonFor('b')?.isLocked, isTrue);
    });

    test('a chapter with no course stands alone', () {
      final subjects = [
        SubjectModel(id: 's1', subject: 'one', order: 1),
        SubjectModel(id: 's2', subject: 'two', order: 1),
      ];
      final syllabus = CourseSyllabus.forChapter(
        subjectId: 's1',
        subjects: subjects,
        lessonsFor: (id) => [_lesson('a$id', id)],
        progress: const {},
      );

      expect(syllabus.chapters.map((c) => c.id), ['s1']);
    });

    test('an unknown chapter gives an empty syllabus', () {
      final syllabus = CourseSyllabus.forChapter(
        subjectId: 'missing',
        subjects: [SubjectModel(id: 's1', subject: 'one', order: 1)],
        lessonsFor: (_) => const [],
        progress: const {},
      );

      expect(syllabus.isEmpty, isTrue);
      expect(syllabus.chapters, isEmpty);
    });
  });

  group('CourseLessonSummary', () {
    test('adds up chapters and lessons', () {
      final summary = CourseLessonSummary.from(const [
        ChapterProgress(total: 8, completed: 8),
        ChapterProgress(total: 8, completed: 3, started: 1),
      ]);

      expect(summary.chapterCount, 2);
      expect(summary.lessons.total, 16);
      expect(summary.lessons.completed, 11);
      expect(summary.subtitle, '2 Chapters · 11/16 Lessons');
    });

    test('reads "1 Chapter" and leaves out lessons when there are none', () {
      final summary = CourseLessonSummary.from(const [
        ChapterProgress(total: 0),
      ]);

      expect(summary.subtitle, '1 Chapter');
    });
  });
}
