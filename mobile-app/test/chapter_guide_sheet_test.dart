import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    expect(find.text('Got It'), findsOneWidget);
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
    expect(ChapterGuideSheet.iconFor('video'), LucideIcons.circlePlay);
    expect(ChapterGuideSheet.iconFor('quiz'), LucideIcons.listChecks);
    expect(ChapterGuideSheet.iconFor('progress'), LucideIcons.trendingUp);
    expect(ChapterGuideSheet.iconFor('anything-else'), LucideIcons.info);
  });
}
