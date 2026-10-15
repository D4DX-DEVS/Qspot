import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/quiz/model/quiz_progress_record.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/quiz/widgets/quiz_logout_warning_dialog.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/services/quiz_offline_store.dart';
import 'package:qspot/services/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

QuizProgressRecord _copy(
  String quizId, {
  Map<String, int?> answers = const {'a': 1},
  bool submitPending = false,
  int? rejectedStatus,
}) => QuizProgressRecord(
  quizId: quizId,
  title: 'Quiz $quizId',
  questionIds: const ['a'],
  answers: answers,
  language: 'en',
  startedAt: DateTime(2026, 10, 14, 10),
  submitPending: submitPending,
  rejectedStatus: rejectedStatus,
);

/// Logging out with quiz answers the server does not have yet warns first,
/// and logging out anyway deletes them from the phone.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.setString('userId', 'u1');
  });

  test('unsent means waiting to send, or started with an answer', () async {
    await QuizOfflineStore.saveProgress(
      'u1',
      _copy('waiting', submitPending: true),
    );
    await QuizOfflineStore.saveProgress('u1', _copy('started'));
    await QuizOfflineStore.saveProgress(
      'u1',
      _copy('blank', answers: const {'a': null}),
    );
    await QuizOfflineStore.saveProgress(
      'u1',
      _copy('refused', submitPending: true, rejectedStatus: 403),
    );
    await QuizOfflineStore.saveProgress(
      'u2',
      _copy('other', submitPending: true),
    );

    expect(await QuizProvider().unsentQuizCount(), 2);
  });

  test("logging out deletes only this student's saved quizzes", () async {
    await QuizOfflineStore.saveSession('u1', 'q1', {'title': 'x'});
    await QuizOfflineStore.saveProgress('u1', _copy('q1'));
    await QuizOfflineStore.saveProgress('u2', _copy('q9'));

    await QuizProvider().deleteSavedQuizzes();

    expect(await QuizOfflineStore.loadSession('u1', 'q1'), isNull);
    expect(await QuizOfflineStore.loadProgress('u1', 'q1'), isNull);
    expect(await QuizOfflineStore.loadProgress('u2', 'q9'), isNotNull);
  });

  test('the warning names how many quizzes', () {
    expect(QuizLogoutWarningDialog.message(1), contains('answers for 1 quiz'));
    expect(
      QuizLogoutWarningDialog.message(3),
      contains('answers for 3 quizzes'),
    );
    expect(
      QuizLogoutWarningDialog.message(1),
      contains('deleted from this phone'),
    );
  });

  group('asking before logging out', () {
    Future<bool?> askToLogOut(WidgetTester tester) async {
      bool? result;
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => QuizProvider(),
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await confirmLogout(context),
                child: const Text('Log out'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Log out'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('with unsent answers: the warning, and Stay Logged In', (
      tester,
    ) async {
      await tester.runAsync(
        () => QuizOfflineStore.saveProgress(
          'u1',
          _copy('q1', submitPending: true),
        ),
      );
      await askToLogOut(tester);

      expect(find.text('Unsent Quiz Answers'), findsOneWidget);
      await tester.tap(find.text('Stay Logged In'));
      await tester.pumpAndSettle();
      expect(find.text('Unsent Quiz Answers'), findsNothing);
    });

    testWidgets('with unsent answers: Log Out and Delete goes ahead', (
      tester,
    ) async {
      await tester.runAsync(
        () => QuizOfflineStore.saveProgress('u1', _copy('q1')),
      );
      bool? result;
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => QuizProvider(),
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await confirmLogout(context),
                child: const Text('Log out'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Log out'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log Out and Delete'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('with nothing unsent: the usual question', (tester) async {
      await askToLogOut(tester);
      expect(find.text('Are you sure you want to logout?'), findsOneWidget);
      expect(find.text('Unsent Quiz Answers'), findsNothing);
    });
  });
}
