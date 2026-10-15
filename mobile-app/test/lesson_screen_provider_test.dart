import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/course/model/lesson_status.dart';
import 'package:qspot/screens/lesson/model/lesson_tab.dart';
import 'package:qspot/screens/lesson/provider/lesson_screen_provider.dart';
import 'package:qspot/screens/subject/model/subject_model.dart';
import 'package:qspot/screens/video/model/video_model.dart';
import 'package:qspot/services/course_service.dart';
import 'package:qspot/services/video_progress_service.dart';

/// Stands in for the app's video, subject and bookmark lists.
class _Source extends ChangeNotifier {
  Map<String, VideoProgressStatus> progress = {};
  bool saved = false;

  void finish(String id) {
    progress = {
      ...progress,
      id: VideoProgressStatus(videoId: id, completed: true),
    };
    notifyListeners();
  }
}

VideoModel _lesson(
  String id,
  String chapter, {
  bool upcoming = false,
  int questions = 0,
}) => VideoModel(
  id: id,
  caption: '',
  video: 'x',
  title: 'Lesson $id',
  subjectId: chapter,
  subjectName: 'name of $chapter',
  isUpcoming: upcoming,
  questionCount: questions,
);

final _lessons = {
  's1': [_lesson('a', 's1'), _lesson('b', 's1', questions: 3)],
  's2': [_lesson('c', 's2'), _lesson('d', 's2')],
  's3': [_lesson('x', 's3')],
};

LessonScreenProvider _provider(
  _Source source,
  VideoModel video, {
  bool known = true,
  Future<void> Function()? refresh,
}) => LessonScreenProvider(
  video: video,
  inputsChanged: source,
  readInputs: () => (
    subjects: known
        ? [
            SubjectModel(
              id: 's1',
              subject: 'letters',
              order: 1,
              courseId: 'c1',
            ),
            SubjectModel(id: 's2', subject: 'madd', order: 2, courseId: 'c1'),
            SubjectModel(id: 's3', subject: 'solo', order: 1),
          ]
        : <SubjectModel>[],
    courses: const [CourseModel(id: 'c1', title: 'Tajweed')],
    lessonsFor: (id) => _lessons[id] ?? const [],
    progress: source.progress,
  ),
  readSaved: () => source.saved,
  toggleSavedState: () async {
    source.saved = !source.saved;
    return true;
  },
  refreshProgress: refresh,
);

VideoModel _video(String id) =>
    _lessons.values.expand((list) => list).firstWhere((v) => v.id == id);

void main() {
  group('where the lesson sits', () {
    test('says which lesson of its chapter it is, and where', () {
      final provider = _provider(_Source(), _video('b'));

      expect(provider.positionLabel, 'Lesson 2 of 2');
      expect(provider.crumb, 'Tajweed · Chapter 1');
      expect(provider.chapterTitle, 'Letters');
      expect(provider.subtitle, startsWith('Letters'));
    });

    test('finds the lessons before and after, across chapters', () {
      final first = _provider(_Source(), _video('a'));
      expect(first.previous, isNull);
      expect(first.next?.id, 'b');

      final middle = _provider(_Source(), _video('b'));
      expect(middle.previous?.id, 'a');
      expect(middle.next?.id, 'c');

      final last = _provider(_Source(), _video('d'));
      expect(last.previous?.id, 'c');
      expect(last.next, isNull);
    });

    test('a chapter outside any course stands alone', () {
      final provider = _provider(_Source(), _video('x'));

      expect(provider.positionLabel, 'Lesson 1 of 1');
      expect(provider.crumb, 'Chapter 1');
      expect(provider.previous, isNull);
      expect(provider.next, isNull);
    });

    test('a lesson the course does not know still works', () {
      final provider = _provider(_Source(), _video('a'), known: false);

      expect(provider.positionLabel, isNull);
      expect(provider.crumb, 'name of s1');
      expect(provider.status, isNull);
      expect(provider.canPlay, isTrue);
      expect(provider.previous, isNull);
      expect(provider.next, isNull);
    });
  });

  group('playing', () {
    test('the first lesson is open to begin with', () {
      final provider = _provider(_Source(), _video('a'));

      expect(provider.canPlay, isTrue);
      expect(provider.status, LessonStatus.notStarted);
      expect(provider.playLabel, 'Watch lesson');
    });

    test('a later lesson can be played before the ones ahead of it', () {
      final provider = _provider(_Source(), _video('c'));

      expect(provider.status, LessonStatus.notStarted);
      expect(provider.canPlay, isTrue);
      expect(provider.playBlockedMessage, isNull);
      expect(provider.playLabel, 'Watch lesson');
    });

    test('a lesson that has not been released cannot be played', () {
      final provider = _provider(
        _Source(),
        _lesson('soon', 's9', upcoming: true),
        known: false,
      );

      expect(provider.canPlay, isFalse);
      expect(provider.playBlockedMessage, 'This lesson has not opened yet.');
    });

    test('a lesson being watched offers to resume where it stopped', () {
      final source = _Source()
        ..progress = {
          'a': const VideoProgressStatus(videoId: 'a', positionSeconds: 380),
        };

      final provider = _provider(source, _video('a'));

      expect(provider.status, LessonStatus.inProgress);
      expect(provider.playLabel, 'Resume at 6:20');
    });

    test('a finished lesson offers to watch again', () {
      final source = _Source()..finish('a');

      expect(_provider(source, _video('a')).playLabel, 'Watch again');
    });

    test('the picture shows the time reached and the length', () {
      final source = _Source()
        ..progress = {
          'a': const VideoProgressStatus(
            videoId: 'a',
            positionSeconds: 380,
            durationSeconds: 840,
          ),
        };

      final provider = _provider(source, _video('a'));

      expect(provider.positionText, '6:20');
      // The progress row knows the length when the lesson itself does not.
      expect(provider.durationText, '14:00');
    });

    test(
      'a lesson not started yet reads from 0:00, and an unknown length is left out',
      () {
        final provider = _provider(_Source(), _video('a'));

        expect(provider.positionText, '0:00');
        expect(provider.durationText, isNull);
      },
    );

    test('the lesson length from its own record is used first', () {
      final video = VideoModel(
        id: 'z',
        caption: '',
        video: 'x',
        title: 'Lesson z',
        subjectId: 's1',
        durationSeconds: 125,
      );

      expect(_provider(_Source(), video).durationText, '2:05');
    });

    test('the heading line gives the chapter and the full date', () {
      final video = _video('a').copyWith(date: DateTime(2026, 10, 11, 9));

      expect(_provider(_Source(), video).subtitle, 'Letters · 11 Oct 2026');
    });
  });

  group('the next lesson', () {
    test('is open before this lesson is finished', () {
      final provider = _provider(_Source(), _video('a'));

      expect(provider.canOpenNext, isTrue);
      expect(provider.nextHint, isNull);
    });

    test('stays shut, with a note, until it is released', () {
      final soon = _lesson('soon', 's1', upcoming: true);
      final provider = LessonScreenProvider(
        video: _video('a'),
        inputsChanged: _Source(),
        readInputs: () => (
          subjects: [SubjectModel(id: 's1', subject: 'letters', order: 1)],
          courses: const <CourseModel>[],
          lessonsFor: (_) => [_video('a'), soon],
          progress: const <String, VideoProgressStatus>{},
        ),
        readSaved: () => false,
        toggleSavedState: () async => false,
      );

      expect(provider.next?.id, 'soon');
      expect(provider.canOpenNext, isFalse);
      expect(provider.nextHint, 'The next lesson has not opened yet.');
    });

    test('has no note on the last lesson', () {
      final provider = _provider(_Source(), _video('d'));

      expect(provider.canOpenNext, isFalse);
      expect(provider.nextHint, isNull);
    });
  });

  group('practice', () {
    test('unlocks once the lesson is finished', () {
      final source = _Source();
      final provider = _provider(source, _video('b'));
      expect(provider.practiceUnlocked, isFalse);
      expect(provider.questionCount, 3);

      source.finish('b');

      expect(provider.practiceUnlocked, isTrue);
    });

    test('takes the larger of the two question counts', () {
      final source = _Source()
        ..progress = {
          'a': const VideoProgressStatus(videoId: 'a', questionCount: 5),
        };

      expect(_provider(source, _video('a')).questionCount, 5);
    });
  });

  test('progress changes move the page on', () {
    final source = _Source();
    final provider = _provider(source, _video('c'));
    expect(provider.status, LessonStatus.notStarted);

    source.finish('c');

    expect(provider.status, LessonStatus.completed);
    expect(provider.playLabel, 'Watch again');
  });

  test('choosing a tab changes it once', () {
    final provider = _provider(_Source(), _video('a'));
    var notified = 0;
    provider.addListener(() => notified++);

    provider.selectTab(LessonTab.practice);
    provider.selectTab(LessonTab.practice);

    expect(provider.tab, LessonTab.practice);
    expect(notified, 1);
  });

  test('saving toggles the bookmark and reports the new state', () async {
    final source = _Source();
    final provider = _provider(source, _video('a'));

    expect(provider.isSaved, isFalse);
    expect(await provider.toggleSaved(), isTrue);
    expect(provider.isSaved, isTrue);
    expect(await provider.toggleSaved(), isFalse);
  });

  test('progress is reloaded after the lesson is watched', () async {
    var reloads = 0;
    final provider = _provider(
      _Source(),
      _video('a'),
      refresh: () async => reloads++,
    );

    await provider.refreshProgress();

    expect(reloads, 1);
  });

  test('stops listening once disposed', () {
    final source = _Source();
    final provider = _provider(source, _video('a'));

    provider.dispose();

    // A disposed provider that still listened would throw when it rebuilt.
    expect(() => source.finish('a'), returnsNormally);
  });
}
