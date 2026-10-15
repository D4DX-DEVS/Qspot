import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:qspot/routes/app_routes.dart';
import 'package:qspot/screens/certificate/screens/certificates_screen.dart';
import 'package:qspot/screens/grades/screens/grades_screen.dart';
import 'package:qspot/screens/progress/screens/progress_screen.dart';
import 'package:qspot/screens/video/provider/video_provider.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:qspot/services/learning_progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// 8/10 quiz, 4/5 lesson practice and an assignment marked 82/100.
http.Response _marks(http.Request request) => switch (request.url.path) {
  '/api/user/progress' => _json({
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
  }),
  '/api/user/assignments' => _json([
    {
      '_id': 'a1',
      'title': 'Steps of wudu',
      'maxPoints': 100,
      'submission': {
        'status': 'graded',
        'grade': 82,
        'feedback': 'Well done',
        'submittedAt': '2026-10-10T09:00:00Z',
        'gradedAt': '2026-10-12T09:00:00Z',
      },
    },
  ]),
  _ => _json([]),
};

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  required http.Response Function(http.Request) respond,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  // The test font is one em wide per glyph, so rows that fit on a device
  // still report overflow here.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exception.toString().contains('A RenderFlex overflowed')) {
      return;
    }
    previousOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = previousOnError);

  SharedPreferences.setMockInitialValues({});
  await StorageService.init();
  ApiClient.clientOverride = MockClient((request) async => respond(request));
  addTearDown(() => ApiClient.clientOverride = null);

  await tester.pumpWidget(
    MaterialApp(home: home, onGenerateRoute: AppRoutes.onGenerateRoute),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('My Grades', () {
    testWidgets('lists every mark with the average on top', (tester) async {
      await _pump(tester, const GradesScreen(), respond: _marks);

      expect(find.text('81% Average'), findsOneWidget);
      expect(find.text('3 grades so far'), findsOneWidget);
      expect(find.text('Chapter 1 quiz'), findsOneWidget);
      expect(find.text('Madd Asli'), findsOneWidget);
      expect(find.text('Steps of wudu'), findsOneWidget);
      expect(find.text('8/10'), findsOneWidget);
      expect(find.text('82/100'), findsOneWidget);
      expect(find.text('Teacher: Well done'), findsOneWidget);
    });

    testWidgets('shows the newest mark first', (tester) async {
      await _pump(tester, const GradesScreen(), respond: _marks);

      final assignmentY = tester.getTopLeft(find.text('Steps of wudu')).dy;
      final practiceY = tester.getTopLeft(find.text('Madd Asli')).dy;
      final quizY = tester.getTopLeft(find.text('Chapter 1 quiz')).dy;
      expect(assignmentY, lessThan(practiceY));
      expect(practiceY, lessThan(quizY));
    });

    testWidgets('a filter shows only that kind', (tester) async {
      await _pump(tester, const GradesScreen(), respond: _marks);

      // The chips scroll sideways; bring the last one into view first.
      await tester.ensureVisible(find.text('Assignments (1)'));
      await tester.pump();
      await tester.tap(find.text('Assignments (1)'));
      await tester.pump();

      expect(find.text('Steps of wudu'), findsOneWidget);
      expect(find.text('Chapter 1 quiz'), findsNothing);
      expect(find.text('Madd Asli'), findsNothing);
    });

    testWidgets('a learner with no marks sees a friendly empty state', (
      tester,
    ) async {
      await _pump(
        tester,
        const GradesScreen(),
        respond: (_) => _json({'quizAttempts': [], 'videoQuizzes': []}),
      );

      expect(find.text('No Grades Yet'), findsOneWidget);
    });

    testWidgets('a failed load says so and offers a retry', (tester) async {
      var fail = true;
      await _pump(
        tester,
        const GradesScreen(),
        respond: (request) =>
            fail ? _json({'message': 'boom'}, 500) : _marks(request),
      );

      expect(find.text('Could Not Load Grades'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Retry'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chapter 1 quiz'), findsOneWidget);
    });

    testWidgets('assignment marks are left out if only they fail to load', (
      tester,
    ) async {
      await _pump(
        tester,
        const GradesScreen(),
        respond: (request) => request.url.path == '/api/user/assignments'
            ? _json({'message': 'boom'}, 500)
            : _marks(request),
      );

      expect(find.text('Chapter 1 quiz'), findsOneWidget);
      expect(find.text('Steps of wudu'), findsNothing);
    });
  });

  group('My Certificates', () {
    http.Response certificates(http.Request request) => _json({
      'items': [
        {
          'id': 'c1',
          'certificateNumber': 'QS-0001',
          'snapshot': {'examTitle': 'Final Exam'},
          'percentage': 87.5,
          'score': 7,
          'totalQuestions': 8,
          'issuedAt': '2026-10-07T12:00:00Z',
          'student': {'name': 'Aisha'},
        },
      ],
    });

    testWidgets('lists each certificate with its exam and mark', (
      tester,
    ) async {
      await _pump(tester, const CertificatesScreen(), respond: certificates);

      expect(find.text('Final Exam'), findsOneWidget);
      expect(find.text('Issued 7 October 2026'), findsOneWidget);
      expect(find.text('87.5%'), findsOneWidget);
    });

    testWidgets('a learner with none sees a friendly empty state', (
      tester,
    ) async {
      await _pump(
        tester,
        const CertificatesScreen(),
        respond: (_) => _json({'items': []}),
      );

      expect(find.text('No Certificates Yet'), findsOneWidget);
    });

    testWidgets('a failed load says so and offers a retry', (tester) async {
      await _pump(
        tester,
        const CertificatesScreen(),
        respond: (_) => _json({'message': 'boom'}, 500),
      );

      expect(find.text('Could Not Load Certificates'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Progress', () {
    Future<void> pumpProgress(WidgetTester tester) => _pump(
      tester,
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => VideoProvider())],
        child: ProgressScreen(
          loadData: () async => LearningProgressData(
            videosTotal: 4,
            videosCompleted: 1,
            activities: [
              ProgressActivity(
                kind: 'assignment',
                title: 'Steps of wudu',
                score: 82,
                totalQuestions: 100,
                percentage: 82,
                createdAt: DateTime(2026, 10, 12),
                detail: '82/100 points - 82%',
              ),
            ],
          ),
        ),
      ),
      respond: _marks,
    );

    testWidgets('Recent Activity lists a marked assignment', (tester) async {
      await pumpProgress(tester);

      await tester.scrollUntilVisible(find.text('Steps of wudu'), 200);

      expect(find.text('Assignment'), findsOneWidget);
      expect(find.text('Steps of wudu'), findsOneWidget);
      expect(find.text('82/100 points - 82%'), findsOneWidget);
    });

    testWidgets('has rows that open My Grades and My Certificates', (
      tester,
    ) async {
      await pumpProgress(tester);

      await tester.scrollUntilVisible(find.text('My Certificates'), 200);
      expect(find.text('My Grades'), findsOneWidget);

      await tester.tap(find.text('My Grades'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();

      expect(find.text('81% Average'), findsOneWidget);
    });

    testWidgets('the My Certificates row opens the certificates', (
      tester,
    ) async {
      await pumpProgress(tester);

      await tester.scrollUntilVisible(find.text('My Certificates'), 200);
      await tester.tap(find.text('My Certificates'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CertificatesScreen), findsOneWidget);
    });
  });
}
