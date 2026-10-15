import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qspot/screens/subject/model/subject_model.dart';
import 'package:qspot/screens/subject/widgets/subject_card.dart';

Future<void> _pump(WidgetTester tester, SubjectModel subject, int done) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SubjectCard(
            subject: subject,
            onTap: () {},
            width: 148,
            height: 197,
            completedLessons: done,
            totalLessons: 4,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('with cover art the name is not drawn a second time', (
    tester,
  ) async {
    await _pump(
      tester,
      SubjectModel(
        id: 's',
        subject: 'Qur’anic Stories',
        subImage: 'https://example.invalid/art.png',
      ),
      1,
    );
    expect(find.text('Qur’anic Stories'), findsNothing);
    expect(find.text('1/4'), findsOneWidget);
  });

  testWidgets('without cover art the name is shown on the card', (
    tester,
  ) async {
    await _pump(tester, SubjectModel(id: 's', subject: 'Stories'), 1);
    expect(find.text('Stories'), findsOneWidget);
  });

  testWidgets('a finished chapter gets a gold check', (tester) async {
    await _pump(tester, SubjectModel(id: 's', subject: 'Stories'), 4);
    expect(find.byIcon(LucideIcons.check), findsOneWidget);
  });

  testWidgets('an unfinished chapter has no check', (tester) async {
    await _pump(tester, SubjectModel(id: 's', subject: 'Stories'), 3);
    expect(find.byIcon(LucideIcons.check), findsNothing);
  });
}
