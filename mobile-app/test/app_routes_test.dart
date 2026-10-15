import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:qspot/routes/app_routes.dart';
import 'package:qspot/screens/assignment/screens/assignments_screen.dart';
import 'package:qspot/screens/calendar/screens/calendar_screen.dart';
import 'package:qspot/screens/certificate/screens/certificates_screen.dart';
import 'package:qspot/screens/common/widgets/home_theme_scope.dart';
import 'package:qspot/screens/grades/screens/grades_screen.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/quiz/screens/quiz_list_screen.dart';
import 'package:qspot/screens/schedule/provider/schedule_provider.dart';
import 'package:qspot/screens/schedule/screens/schedule_screen.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/common/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('the route table', () {
    test('every name in the table gives a page, and keeps its name', () {
      for (final name in AppRoutes.names) {
        final route = AppRoutes.onGenerateRoute(RouteSettings(name: name));

        expect(route, isA<MaterialPageRoute<dynamic>>(), reason: name);
        expect(route!.settings.name, name);
      }
    });

    test('names are unique and start with a slash', () {
      expect(AppRoutes.names.toSet(), hasLength(AppRoutes.names.length));
      expect(AppRoutes.names.every((name) => name.startsWith('/')), isTrue);
    });

    test('a name that is not in the table gives nothing', () {
      expect(
        AppRoutes.onGenerateRoute(const RouteSettings(name: '/nope')),
        isNull,
      );
      expect(AppRoutes.onGenerateRoute(const RouteSettings()), isNull);
    });
  });

  group('opening by name', () {
    final screens = <String, Type>{
      AppRoutes.calendar: CalendarScreen,
      AppRoutes.grades: GradesScreen,
      AppRoutes.certificates: CertificatesScreen,
      AppRoutes.assignments: AssignmentsScreen,
      AppRoutes.quizzes: QuizListScreen,
      AppRoutes.schedule: ScheduleScreen,
    };

    test('the test list covers the whole table', () {
      expect(screens.keys.toSet(), AppRoutes.names.toSet());
    });

    for (final entry in screens.entries) {
      testWidgets('${entry.key} opens ${entry.value}', (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        // The test font is one em wide per glyph, so rows that fit on a
        // device still report overflow here.
        final previousOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.exception.toString().contains(
            'A RenderFlex overflowed',
          )) {
            return;
          }
          previousOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = previousOnError);

        SharedPreferences.setMockInitialValues({});
        await StorageService.init();
        ApiClient.clientOverride = MockClient(
          (_) async => http.Response('[]', 200),
        );
        addTearDown(() => ApiClient.clientOverride = null);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => QuizProvider()),
              ChangeNotifierProvider(create: (_) => ScheduleProvider()),
            ],
            child: MaterialApp(
              onGenerateRoute: AppRoutes.onGenerateRoute,
              home: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.pushNamed(context, entry.key),
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Go'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(HomeThemeScope), findsWidgets);
        expect(
          find.byWidgetPredicate((w) => w.runtimeType == entry.value),
          findsOneWidget,
        );
      });
    }
  });
}
