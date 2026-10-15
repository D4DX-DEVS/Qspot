import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/assignment/model/assignment_model.dart';
import 'package:qspot/screens/grades/model/grade_entry.dart';
import 'package:qspot/screens/grades/model/grade_filter.dart';
import 'package:qspot/screens/grades/model/grade_kind.dart';
import 'package:qspot/screens/grades/provider/grades_provider.dart';
import 'package:qspot/screens/grades/service/grades_service.dart';

GradeEntry _entry(
  GradeKind kind,
  String title,
  num score,
  num outOf, {
  DateTime? date,
}) => GradeEntry(
  kind: kind,
  title: title,
  score: score,
  outOf: outOf,
  date: date,
);

void main() {
  group('GradeEntry', () {
    test('reads a score out of a total as a percentage', () {
      final entry = _entry(GradeKind.quiz, 'Quiz', 8, 10);

      expect(entry.percent, 80);
      expect(entry.percentLabel, '80%');
      expect(entry.scoreLabel, '8/10');
    });

    test('shows a decimal mark only when it is not whole', () {
      final entry = _entry(GradeKind.assignment, 'Essay', 82.5, 100);

      expect(entry.scoreLabel, '82.5/100');
      expect(entry.percentLabel, '83%');
    });

    test('a total of nothing is 0%, and a mark cannot pass 100%', () {
      expect(_entry(GradeKind.quiz, 'a', 3, 0).percent, 0);
      expect(_entry(GradeKind.quiz, 'b', 12, 10).percent, 100);
    });
  });

  group('GradeFilter', () {
    test('All shows every kind and the others show only their own', () {
      expect(GradeKind.values.every(GradeFilter.all.matches), isTrue);
      expect(GradeFilter.quizzes.matches(GradeKind.quiz), isTrue);
      expect(GradeFilter.quizzes.matches(GradeKind.assignment), isFalse);
      expect(GradeFilter.lessons.matches(GradeKind.lessonPractice), isTrue);
      expect(GradeFilter.lessons.matches(GradeKind.quiz), isFalse);
      expect(GradeFilter.assignments.matches(GradeKind.assignment), isTrue);
      expect(
        GradeFilter.assignments.matches(GradeKind.lessonPractice),
        isFalse,
      );
    });
  });

  group('GradesService', () {
    test('reads quiz and lesson practice marks from the progress body', () {
      final entries = GradesService.fromProgress({
        'quizAttempts': [
          {
            'title': 'Chapter 1 quiz',
            'score': 8,
            'totalQuestions': 10,
            'createdAt': '2026-10-08T09:00:00Z',
          },
        ],
        'videoQuizzes': [
          {
            'videoId': 'v1',
            'title': 'Madd Asli',
            'score': 4,
            'totalQuestions': 5,
            'createdAt': '2026-10-11T09:00:00Z',
          },
        ],
      });

      expect(entries.map((e) => e.kind), [
        GradeKind.quiz,
        GradeKind.lessonPractice,
      ]);
      expect(entries[0].scoreLabel, '8/10');
      expect(entries[0].videoId, isNull);
      expect(entries[1].videoId, 'v1');
      expect(entries[1].date, DateTime.parse('2026-10-11T09:00:00Z'));
    });

    test('skips rows with no title and tolerates a missing body', () {
      expect(
        GradesService.fromProgress({
          'quizAttempts': [
            {'score': 1, 'totalQuestions': 2},
          ],
        }),
        isEmpty,
      );
      expect(GradesService.fromProgress(null), isEmpty);
      expect(GradesService.fromProgress(<dynamic>[]), isEmpty);
    });

    test('keeps only the assignments a teacher has marked', () {
      final entries = GradesService.fromAssignments([
        AssignmentModel.fromJson({
          '_id': 'a1',
          'title': 'Steps of wudu',
          'maxPoints': 100,
          'courseId': {'_id': 'c1'},
          'subjectId': 's1',
          'submission': {
            'status': 'graded',
            'grade': 82,
            'feedback': ' Well done ',
            'submittedAt': '2026-10-10T09:00:00Z',
            'gradedAt': '2026-10-12T09:00:00Z',
          },
        }),
        AssignmentModel.fromJson({
          '_id': 'a2',
          'title': 'Handed in, not marked',
          'submission': {
            'status': 'submitted',
            'submittedAt': '2026-10-10T09:00:00Z',
          },
        }),
        AssignmentModel.fromJson({'_id': 'a3', 'title': 'Not started'}),
      ]);

      expect(entries, hasLength(1));
      final entry = entries.single;
      expect(entry.kind, GradeKind.assignment);
      expect(entry.scoreLabel, '82/100');
      expect(entry.feedback, 'Well done');
      expect(entry.courseId, 'c1');
      expect(entry.subjectId, 's1');
      expect(entry.date, DateTime.parse('2026-10-12T09:00:00Z'));
    });

    test('a mark of zero still counts as marked', () {
      final entries = GradesService.fromAssignments([
        AssignmentModel.fromJson({
          '_id': 'a1',
          'title': 'Zero',
          'maxPoints': 10,
          'submission': {'status': 'graded', 'grade': 0},
        }),
      ]);

      expect(entries.single.score, 0);
      expect(entries.single.percentLabel, '0%');
    });
  });

  group('GradesProvider', () {
    final older = DateTime(2026, 10, 1);
    final newer = DateTime(2026, 10, 9);
    List<GradeEntry> sample() => [
      _entry(GradeKind.quiz, 'Old quiz', 5, 10, date: older),
      _entry(GradeKind.assignment, 'New work', 9, 10, date: newer),
      _entry(GradeKind.lessonPractice, 'No date', 1, 2),
    ];

    test('lists marks newest first, undated last', () async {
      final provider = GradesProvider(fetch: () async => sample());

      await provider.load();

      expect(provider.entries.map((e) => e.title), [
        'New work',
        'Old quiz',
        'No date',
      ]);
    });

    test('averages every mark', () async {
      final provider = GradesProvider(fetch: () async => sample());
      expect(provider.average, isNull);

      await provider.load();

      // 50%, 90% and 50% make 63.3%.
      expect(provider.average!.round(), 63);
    });

    test('a filter narrows the list and counts what it would hold', () async {
      final provider = GradesProvider(fetch: () async => sample());
      await provider.load();

      provider.selectFilter(GradeFilter.assignments);

      expect(provider.visible.map((e) => e.title), ['New work']);
      expect(provider.countFor(GradeFilter.all), 3);
      expect(provider.countFor(GradeFilter.quizzes), 1);
      expect(provider.countFor(GradeFilter.lessons), 1);
    });

    test('no marks reads as empty, not as an error', () async {
      final provider = GradesProvider(fetch: () async => const []);
      expect(provider.isEmpty, isFalse);

      await provider.load();

      expect(provider.isEmpty, isTrue);
      expect(provider.showError, isFalse);
      expect(provider.average, isNull);
    });

    test('a failed load shows an error until a retry works', () async {
      var attempts = 0;
      final provider = GradesProvider(
        fetch: () async {
          attempts++;
          if (attempts == 1) throw Exception('offline');
          return sample();
        },
      );

      await provider.load();
      expect(provider.showError, isTrue);
      expect(provider.error, isNotNull);

      await provider.load();
      expect(provider.showError, isFalse);
      expect(provider.entries, hasLength(3));
    });

    test('shows a skeleton only on the first load', () async {
      final provider = GradesProvider(fetch: () async => sample());
      final seen = <bool>[];
      provider.addListener(() => seen.add(provider.showSkeleton));

      await provider.load();
      await provider.load();

      // On while the first load runs, never again.
      expect(seen.first, isTrue);
      expect(seen.skip(2).any((value) => value), isFalse);
    });
  });
}
