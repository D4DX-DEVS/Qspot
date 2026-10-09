import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';
import 'package:qspot/screens/quiz/screens/quiz_question_screen.dart';

/// The number strip in the quiz bottom bar must keep the current question's
/// number visible when moving past the edge of the strip.
void main() {
  Future<QuizProvider> pumpQuiz(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final provider = QuizProvider()
      ..seedSessionForTest([
        for (var i = 0; i < 30; i++)
          {
            '_id': 'id-$i',
            'type': 'multiple_choice',
            'question_en': 'Question body $i',
            'options_en': ['A', 'B', 'C', 'D'],
            'difficulty': 'easy',
          },
      ]);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: QuizQuestionScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return provider;
  }

  Finder strip() => find.byWidgetPredicate(
    (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
  );

  bool dotVisible(WidgetTester tester, int number) {
    final viewport = tester.getRect(strip());
    final dot = tester.getRect(
      find.descendant(of: strip(), matching: find.text('$number')),
    );
    return dot.left >= viewport.left && dot.right <= viewport.right;
  }

  double stripOffset(WidgetTester tester) =>
      tester.widget<SingleChildScrollView>(strip()).controller!.offset;

  testWidgets('pressing Next past the edge scrolls the current number in', (
    tester,
  ) async {
    await pumpQuiz(tester);
    expect(dotVisible(tester, 13), isFalse);

    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byIcon(LucideIcons.arrowRight));
      await tester.pumpAndSettle();
    }

    expect(dotVisible(tester, 13), isTrue);
  });

  testWidgets('jumping back to the first question scrolls back to it', (
    tester,
  ) async {
    final provider = await pumpQuiz(tester);
    provider.goToQuestion(29);
    await tester.pumpAndSettle();
    expect(dotVisible(tester, 30), isTrue);
    expect(dotVisible(tester, 1), isFalse);

    provider.goToQuestion(0);
    await tester.pumpAndSettle();
    expect(dotVisible(tester, 1), isTrue);
  });

  testWidgets('does not scroll while the current number is already visible', (
    tester,
  ) async {
    final provider = await pumpQuiz(tester);
    provider.goToQuestion(1);
    await tester.pumpAndSettle();
    expect(stripOffset(tester), 0);
  });

  testWidgets('a rebuild without a question change keeps a manual scroll', (
    tester,
  ) async {
    final provider = await pumpQuiz(tester);
    await tester.drag(strip(), const Offset(-200, 0));
    await tester.pumpAndSettle();
    final scrolled = stripOffset(tester);
    expect(scrolled, greaterThan(0));

    provider.selectAnswer(1);
    await tester.pumpAndSettle();
    expect(stripOffset(tester), scrolled);
  });
}
