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

  test('missing optional values are handled safely', () {
    final item = AssignmentModel.fromJson({'id': 'a2'});
    expect(item.instructions, isEmpty);
    expect(item.dueAt, isNull);
    expect(item.isSubmitted, isFalse);
    expect(item.isOverdue, isFalse);
  });
}
