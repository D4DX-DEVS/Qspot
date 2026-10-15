import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/quiz/model/quiz_progress_record.dart';
import 'package:qspot/screens/quiz/model/quiz_refusal.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/quiz/screens/quiz_list_screen.dart';
import 'package:qspot/screens/quiz/widgets/quiz_refused_banner.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/services/quiz_offline_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

QuizProgressRecord _refused(String? code, {String quizId = 'q1'}) =>
    QuizProgressRecord(
      quizId: quizId,
      title: 'Weekly Quiz',
      questionIds: const ['a'],
      answers: const {'a': 1},
      language: 'en',
      startedAt: DateTime(2026, 10, 14, 10),
      submitPending: true,
      rejectedStatus: code == 'QUIZ_NOT_FOUND' ? 404 : 403,
      rejectedCode: code,
    );

Map<String, dynamic> _liveQuiz(String id) => {
  '_id': id,
  'title': 'Weekly Quiz',
  'assessmentType': 'quiz',
  'status': 'live',
  'numberOfQuestions': 1,
  'questionCount': 1,
  'myAttempt': null,
};

/// When the teacher switched off, changed or removed a quiz before the
/// student's waiting answers arrived, the student is told why.
void main() {
  group('the reason, in plain words', () {
    test('too late', () {
      expect(
        QuizRefusal.message(_refused('QUIZ_CLOSED')),
        contains('reached us after the quiz closed'),
      );
    });

    test('switched off', () {
      expect(
        QuizRefusal.message(_refused('QUIZ_DISABLED')),
        contains('because the quiz was switched off'),
      );
    });

    test('removed', () {
      expect(
        QuizRefusal.message(_refused('QUIZ_NOT_FOUND')),
        contains('because the quiz was removed'),
      );
    });

    test('questions changed: it can be taken again', () {
      for (final code in ['QUESTIONS_CHANGED', 'NO_SESSION']) {
        final record = _refused(code);
        expect(QuizRefusal.message(record), contains('questions were changed'));
        expect(record.canRetake, isTrue);
      }
      expect(_refused('QUIZ_DISABLED').canRetake, isFalse);
    });

    test('any other refusal still gets a message', () {
      expect(
        QuizRefusal.message(_refused(null)),
        "Your answers for \"Weekly Quiz\" couldn't be submitted. Please speak "
        'to your teacher.',
      );
    });
  });

  group('on the Quiz page', () {
    late List<Map<String, dynamic>> list;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.setString('userId', 'u1');
      list = [];
      ApiClient.clientOverride = MockClient(
        (request) async => http.Response(
          jsonEncode(list),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
    });
    tearDown(() => ApiClient.clientOverride = null);

    Future<QuizProvider> openList(WidgetTester tester) async {
      final provider = QuizProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: QuizListScreen()),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      return provider;
    }

    testWidgets('changed questions on a quiz still open: Open Quiz Again', (
      tester,
    ) async {
      list = [_liveQuiz('q1')];
      await tester.runAsync(
        () =>
            QuizOfflineStore.saveProgress('u1', _refused('QUESTIONS_CHANGED')),
      );
      final provider = await openList(tester);

      expect(find.textContaining('questions were changed'), findsOneWidget);
      await tester.tap(find.text('Open Quiz Again'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      // The old answers are gone and the quiz starts afresh (language first).
      expect(provider.refusedSubmissions, isEmpty);
      expect(find.byType(QuizRefusedBanner), findsNothing);
      expect(find.text('Select Quiz Language'), findsOneWidget);
    });

    testWidgets('switched off: the reason and OK only', (tester) async {
      list = [_liveQuiz('q1')];
      await tester.runAsync(
        () => QuizOfflineStore.saveProgress('u1', _refused('QUIZ_DISABLED')),
      );
      final provider = await openList(tester);

      expect(find.textContaining('switched off'), findsOneWidget);
      expect(find.text('Open Quiz Again'), findsNothing);

      await tester.tap(find.text('OK'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(provider.refusedSubmissions, isEmpty);
      expect(find.byType(QuizRefusedBanner), findsNothing);
    });
  });
}
