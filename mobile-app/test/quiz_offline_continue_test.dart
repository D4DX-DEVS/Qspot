import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/quiz/model/quiz_progress_record.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/quiz/screens/quiz_list_screen.dart';
import 'package:qspot/screens/quiz/screens/quiz_question_screen.dart';
import 'package:qspot/screens/quiz/widgets/quiz_continue_card.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/services/quiz_offline_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

QuizProgressRecord _record({
  String quizId = 'q1',
  bool submitPending = false,
  DateTime? endsAt,
}) => QuizProgressRecord(
  quizId: quizId,
  title: 'Weekly Quiz',
  questionIds: const ['id-0', 'id-1', 'id-2'],
  answers: const {'id-0': 2, 'id-1': null, 'id-2': null},
  language: 'en',
  startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
  currentIndex: 1,
  submitPending: submitPending,
  endsAt: endsAt,
);

Future<void> _saveQuiz(QuizProgressRecord record) async {
  await QuizOfflineStore.saveSession('u1', record.quizId, {
    'title': record.title,
    'questions': [
      for (var i = 0; i < 3; i++)
        {
          '_id': 'id-$i',
          'type': 'multiple_choice',
          'question_en': 'Question body $i',
          'options_en': ['A', 'B', 'C', 'D'],
          'difficulty': 'easy',
        },
    ],
  });
  await QuizOfflineStore.saveProgress('u1', record);
}

/// Offline, with the quiz list unreachable, a quiz started on this phone can
/// still be continued.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.setString('userId', 'u1');
    ApiClient.clientOverride = MockClient(
      (_) async => throw const SocketException('no network'),
    );
  });
  tearDown(() => ApiClient.clientOverride = null);

  test('only quizzes still open and not submitted can be continued', () async {
    final now = DateTime.now();
    await QuizOfflineStore.saveProgress('u1', _record(quizId: 'open'));
    await QuizOfflineStore.saveProgress(
      'u1',
      _record(quizId: 'sent', submitPending: true),
    );
    await QuizOfflineStore.saveProgress(
      'u1',
      _record(
        quizId: 'ended',
        endsAt: now.subtract(const Duration(minutes: 1)),
      ),
    );
    final open = await QuizOfflineStore.inProgress('u1', now);
    expect(open.map((r) => r.quizId), ['open']);
  });

  test(
    'when the list cannot load, the provider offers the started quiz',
    () async {
      await _saveQuiz(_record());
      final provider = QuizProvider();
      await provider.fetchQuizList();
      expect(provider.hasListError, isTrue);
      expect(provider.inProgressQuizzes.single.title, 'Weekly Quiz');
    },
  );

  testWidgets('offline, the student continues the quiz with their answers', (
    tester,
  ) async {
    await tester.runAsync(() => _saveQuiz(_record()));
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

    expect(find.text('Continue Your Quiz'), findsOneWidget);
    expect(find.text('In progress · 1 of 3 answered'), findsOneWidget);

    await tester.tap(find.byType(QuizContinueCard));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(QuizQuestionScreen), findsOneWidget);
    expect(
      find.text('Question body 1'),
      findsOneWidget,
      reason: 'where they left off',
    );
    expect(provider.getSelectedAnswer('id-0'), 2);
    expect(provider.openedFromDevice, isTrue);
  });

  testWidgets('the continue card reads well in dark mode too', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: QuizContinueCard(
            title: 'Weekly Quiz',
            answered: 4,
            total: 10,
            onTap: () => tapped++,
          ),
        ),
      ),
    );
    expect(find.text('In progress · 4 of 10 answered'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    expect(tapped, 1);
    expect(tester.takeException(), isNull);
  });
}
