import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/video/screens/video_questions_screen.dart';
import 'package:qspot/services/video_progress_service.dart';

void main() {
  const questions = [
    VideoQuestionItem(
      id: 'q1',
      questionEn: 'What is the topic of this episode?',
      questionMl: 'ഈ എപ്പിസോഡിന്റെ വിഷയം എന്താണ്?',
      optionsEn: ['Unblemished faith', 'Patience', 'Charity', 'Prayer'],
      optionsMl: ['കളങ്കമില്ലാത്ത ഈമാൻ', 'സബർ', 'ദാനം', 'നമസ്കാരം'],
    ),
    VideoQuestionItem(
      id: 'q2',
      questionEn: 'Who presents this episode?',
      questionMl: 'ഈ എപ്പിസോഡ് അവതരിപ്പിക്കുന്നത് ആരാണ്?',
      optionsEn: ['Basheer Muhiyudheen', 'Suhaib CT'],
      optionsMl: ['ബശീർ മുഹ്യിദ്ദീൻ', 'സി ടി സുഹൈബ്'],
    ),
  ];

  Future<void> pumpScreen(WidgetTester tester, {String locale = 'en'}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VideoQuestionsScreen(
          videoId: 'v1',
          videoTitle: 'Episode 30',
          questions: questions,
          locale: locale,
        ),
      ),
    );
  }

  testWidgets('shows the first question and its options', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Question 1 of 2'), findsOneWidget);
    expect(find.text('What is the topic of this episode?'), findsOneWidget);
    expect(find.text('Unblemished faith'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('serves Malayalam text and options when locale is ml', (
    tester,
  ) async {
    await pumpScreen(tester, locale: 'ml');
    expect(find.text('ഈ എപ്പിസോഡിന്റെ വിഷയം എന്താണ്?'), findsOneWidget);
    expect(find.text('കളങ്കമില്ലാത്ത ഈമാൻ'), findsOneWidget);
  });

  testWidgets('Next stays disabled until an option is chosen', (tester) async {
    await pumpScreen(tester);

    final next = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(next.onPressed, isNull, reason: 'nothing selected yet');

    await tester.tap(find.text('Patience'));
    await tester.pump();

    final enabled = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(enabled.onPressed, isNotNull);
  });

  testWidgets(
    'advances to the next question and shows Submit on the last one',
    (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Patience'));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('Question 2 of 2'), findsOneWidget);
      expect(find.text('Who presents this episode?'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    },
  );
}
