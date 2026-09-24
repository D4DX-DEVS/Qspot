import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/subject/model/subject_model.dart';
import 'package:qspot/screens/subject/widgets/chapter_guide_sheet.dart';

void main() {
  SubjectModel subjectWith(
    List<SubjectGuidePoint> points, {
    String title = '',
  }) {
    return SubjectModel(
      id: 's1',
      subject: 'Ayāt of the Holy Qur’ān',
      subImage: 'https://example.com/cover.jpg',
      guideTitle: title,
      guidePoints: points,
    );
  }

  testWidgets('shows the admin-written heading, lines and the Got it action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChapterGuideSheet(
            subject: subjectWith(const [
              SubjectGuidePoint(
                icon: 'video',
                text: 'Verse-by-verse reflections',
              ),
              SubjectGuidePoint(
                icon: 'quiz',
                text: 'Answer the questions after a video',
              ),
            ], title: 'What is inside this chapter'),
          ),
        ),
      ),
    );

    expect(find.text('What is inside this chapter'), findsOneWidget);
    expect(find.text('Verse-by-verse reflections'), findsOneWidget);
    expect(find.text('Answer the questions after a video'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets(
    'falls back to sensible defaults when the admin has not written one',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChapterGuideSheet(subject: subjectWith(const [])),
          ),
        ),
      );

      expect(find.text(SubjectModel.defaultGuideTitle), findsOneWidget);
      for (final point in SubjectModel.defaultGuidePoints) {
        expect(find.text(point.text), findsOneWidget);
      }
    },
  );

  test('maps the admin icon keys to real icons', () {
    expect(ChapterGuideSheet.iconFor('video'), Icons.play_circle_fill);
    expect(ChapterGuideSheet.iconFor('quiz'), Icons.quiz_outlined);
    expect(ChapterGuideSheet.iconFor('progress'), Icons.trending_up);
    expect(ChapterGuideSheet.iconFor('anything-else'), Icons.info_outline);
  });
}
