import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/home/model/today_section.dart';
import 'package:qspot/screens/home/widgets/today_focus_stat_tile.dart';
import 'package:qspot/screens/home/widgets/today_task_section.dart';
import 'package:qspot/services/today_service.dart';

TodayLearningItem _item(String id, String kind, String status) =>
    TodayLearningItem(
      kind: kind,
      id: id,
      title: 'Title $id',
      status: status,
      dueAt: DateTime.now().add(const Duration(days: 1)),
    );

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  double width = 360,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('TodayTaskSection', () {
    for (final brightness in Brightness.values) {
      for (final (width, scale) in [(320.0, 1.0), (360.0, 2.0), (600.0, 1.0)]) {
        testWidgets('lays out at $width wide, ${scale}x text, $brightness', (
          tester,
        ) async {
          await _pump(
            tester,
            TodayTaskSection(
              section: TodaySection.attention,
              items: [_item('1', 'assignment', 'overdue')],
              onItemTap: (_) {},
              onSeeAll: () {},
            ),
            brightness: brightness,
            width: width,
            textScale: scale,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Needs Your Attention'), findsOneWidget);
          expect(find.text('Past Due - Handle Now'), findsOneWidget);
        });
      }
    }

    testWidgets('shows at most maxItems cards and the right titles', (
      tester,
    ) async {
      await _pump(
        tester,
        TodayTaskSection(
          section: TodaySection.todo,
          maxItems: 2,
          items: [
            for (var i = 0; i < 5; i++) _item('$i', 'assignment', 'upcoming'),
          ],
          onItemTap: (_) {},
        ),
      );
      expect(find.text('Your To-Do List'), findsOneWidget);
      expect(find.text('Title 0'), findsOneWidget);
      expect(find.text('Title 1'), findsOneWidget);
      expect(find.text('Title 2'), findsNothing);
      expect(find.text('Due Tomorrow'), findsNWidgets(2));
      // No link when no handler is given.
      expect(find.text('See All'), findsNothing);
    });

    testWidgets('an overdue item stays flagged inside another block', (
      tester,
    ) async {
      await _pump(
        tester,
        TodayTaskSection(
          section: TodaySection.todo,
          items: [_item('1', 'assignment', 'overdue')],
          onItemTap: (_) {},
        ),
      );
      expect(find.text('Past Due - Handle Now'), findsOneWidget);
    });

    testWidgets('taps report the item and See All', (tester) async {
      TodayLearningItem? tapped;
      var seeAll = 0;
      await _pump(
        tester,
        TodayTaskSection(
          section: TodaySection.comingUp,
          items: [_item('7', 'schedule', 'upcoming')],
          onItemTap: (item) => tapped = item,
          onSeeAll: () => seeAll++,
        ),
      );
      expect(find.text('Coming Up'), findsOneWidget);
      await tester.tap(find.text('Title 7'));
      await tester.pump();
      expect(tapped?.id, '7');
      await tester.tap(find.text('See All'));
      await tester.pump();
      expect(seeAll, 1);
    });

    testWidgets('empty list draws nothing', (tester) async {
      await _pump(
        tester,
        TodayTaskSection(
          section: TodaySection.todo,
          items: const [],
          onItemTap: (_) {},
        ),
      );
      expect(find.byType(Text), findsNothing);
    });
  });

  group('TodayFocusStatTile', () {
    for (final (section, label) in [
      (TodaySection.attention, 'Overdue'),
      (TodaySection.todo, 'To Do'),
      (TodaySection.comingUp, 'Coming Up'),
    ]) {
      for (final brightness in Brightness.values) {
        testWidgets('$section reads "$label" in $brightness', (tester) async {
          await _pump(
            tester,
            SizedBox(
              width: 110,
              child: TodayFocusStatTile(focus: section, count: 3),
            ),
            brightness: brightness,
          );
          expect(tester.takeException(), isNull);
          expect(find.text(label), findsOneWidget);
          expect(find.text('3'), findsOneWidget);
        });
      }
    }
  });
}
