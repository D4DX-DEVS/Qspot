import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/assignment/model/assignment_model.dart';
import 'package:qspot/screens/assignment/service/assignment_service.dart';

void main() {
  test('parses assignment details and nested learner submission', () {
    final item = AssignmentModel.fromJson({
      '_id': 'a1',
      'title': 'Build a mini project',
      'instructions': 'Describe what you made.',
      'subject': {'name': 'Science'},
      'dueAt': '2026-10-04T12:00:00Z',
      'submission': {
        'status': 'graded',
        'text': 'A small model',
        'submittedAt': '2026-10-02T10:00:00Z',
        'feedback': 'Nice work',
        'grade': 9,
      },
    });

    expect(item.id, 'a1');
    expect(item.subject, 'Science');
    expect(item.dueAt, DateTime.parse('2026-10-04T12:00:00Z'));
    expect(item.isSubmitted, isTrue);
    expect(item.submissionText, 'A small model');
    expect(item.feedback, 'Nice work');
    expect(item.grade, '9');
  });

  test('reads the course and chapter a teacher linked it to', () {
    final linkedAsRecords = AssignmentModel.fromJson({
      '_id': 'a1',
      'title': 'Linked',
      'courseId': {'_id': 'c1', 'title': 'Tajweed'},
      'subjectId': {'_id': 's1', 'name': 'Letters'},
    });
    final linkedAsIds = AssignmentModel.fromJson({
      '_id': 'a2',
      'title': 'Linked by id',
      'courseId': 'c2',
      'subjectId': 's2',
    });
    final unlinked = AssignmentModel.fromJson({
      '_id': 'a3',
      'title': 'Unlinked',
      'courseId': null,
    });

    expect(linkedAsRecords.courseId, 'c1');
    expect(linkedAsRecords.subjectId, 's1');
    expect(linkedAsIds.courseId, 'c2');
    expect(linkedAsIds.subjectId, 's2');
    expect(unlinked.courseId, isNull);
    expect(unlinked.subjectId, isNull);
    // The chapter's name shows on the list and the assignment page.
    expect(linkedAsRecords.subject, 'Letters');
    expect(linkedAsIds.subject, isEmpty, reason: 'a bare id is not a name');
    expect(unlinked.subject, isEmpty);
  });

  test('reads what it is marked out of and the teacher mark', () {
    final marked = AssignmentModel.fromJson({
      '_id': 'a1',
      'title': 'Marked',
      'maxPoints': 20,
      'submission': {
        'status': 'graded',
        'grade': 15,
        'gradedAt': '2026-10-12T09:00:00Z',
      },
    });
    final waiting = AssignmentModel.fromJson({
      '_id': 'a2',
      'title': 'Waiting',
      'submission': {'status': 'submitted'},
    });

    expect(marked.maxPoints, 20);
    expect(marked.gradePoints, 15);
    expect(marked.isGraded, isTrue);
    expect(marked.isReviewed, isTrue);
    expect(marked.gradedAt, DateTime.parse('2026-10-12T09:00:00Z'));
    // No total given means 100, and no mark means not graded yet.
    expect(waiting.maxPoints, 100);
    expect(waiting.isGraded, isFalse);
    expect(waiting.isReviewed, isFalse);
    expect(waiting.gradedAt, isNull);
  });

  test('list parser accepts wrapped responses and skips malformed rows', () {
    final items = AssignmentService.parseList({
      'data': {
        'items': [
          {'id': 'a1', 'title': 'First'},
          {'title': 'No id'},
          'bad row',
        ],
      },
    });
    expect(items, hasLength(1));
    expect(items.single.title, 'First');
  });

  test('work returned for changes is to do again', () {
    final item = AssignmentModel.fromJson({
      'id': 'a3',
      'dueAt': '2026-10-04T12:00:00Z',
      'submission': {
        'status': 'returned',
        'text': 'First try',
        'submittedAt': '2026-10-02T10:00:00Z',
        'feedback': 'Hold the madd longer',
      },
    });
    expect(item.isReturned, isTrue);
    expect(item.isSubmitted, isFalse);
    expect(item.isReviewed, isFalse);
    expect(item.feedback, 'Hold the madd longer');
    // Past its deadline, but the teacher asked for it again.
    expect(item.isClosed, isFalse);
  });

  test('a missed deadline closes the work; sent work is not closed', () {
    final missed = AssignmentModel.fromJson({
      'id': 'a4',
      'dueAt': '2026-01-01T00:00:00Z',
    });
    expect(missed.isClosed, isTrue);
    final sent = AssignmentModel.fromJson({
      'id': 'a5',
      'dueAt': '2026-01-01T00:00:00Z',
      'submission': {'status': 'submitted', 'submittedAt': '2025-12-31'},
    });
    expect(sent.isClosed, isFalse);
    final open = AssignmentModel.fromJson({
      'id': 'a6',
      'dueAt': '2099-01-01T00:00:00Z',
    });
    expect(open.isClosed, isFalse);
  });

  test('missing optional values are handled safely', () {
    final item = AssignmentModel.fromJson({'id': 'a2'});
    expect(item.instructions, isEmpty);
    expect(item.dueAt, isNull);
    expect(item.isSubmitted, isFalse);
    expect(item.isOverdue, isFalse);
  });
}
