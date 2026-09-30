import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/services/today_service.dart';

void main() {
  test('parses the optional today contract defensively', () {
    final overview = TodayOverview.fromJson({
      'next': {
        'kind': 'video',
        'id': 'v1',
        'title': 'A lesson',
        'status': 'in-progress',
        'assessmentType': 'practical',
        'subject': {'name': 'Science'},
        'releaseAt': '2026-09-20T00:00:00Z',
        'dueAt': null,
        'percent': 42,
        'estimatedMinutes': '8',
      },
      'continue': [
        {'kind': 'video', 'id': 'v1', 'title': 'A lesson'},
      ],
      'upcoming': 'malformed optional value',
      'streak': {'current': 3, 'best': '7'},
      'summary': {'text': 'One lesson left'},
    });

    expect(overview.next?.id, 'v1');
    expect(overview.next?.subject, 'Science');
    expect(overview.next?.percent, 42);
    expect(overview.next?.estimatedMinutes, 8);
    expect(overview.next?.assessmentType, 'practical');
    expect(overview.continueItems, hasLength(1));
    expect(overview.upcoming, isEmpty);
    expect(overview.currentStreak, 3);
    expect(overview.bestStreak, 7);
    expect(overview.summary, 'One lesson left');
  });

  test('empty or unexpected response fields do not invent progress', () {
    final overview = TodayOverview.fromJson({
      'next': null,
      'continue': null,
      'upcoming': [],
      'streak': null,
      'summary': null,
    });

    expect(overview.next, isNull);
    expect(overview.continueItems, isEmpty);
    expect(overview.upcoming, isEmpty);
    expect(overview.currentStreak, isNull);
    expect(overview.summary, isEmpty);
  });
}
