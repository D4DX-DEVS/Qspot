import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/assignment/model/assignment_model.dart';
import 'package:qspot/screens/assignment/model/rubric_score.dart';
import 'package:qspot/screens/faculty/model/rubric_grade_result.dart';
import 'package:qspot/screens/faculty/model/rubric_spec.dart';
import 'package:qspot/screens/faculty/provider/rubric_grade_provider.dart';
import 'package:qspot/screens/faculty/widgets/rubric_grade_dialog.dart';

const _rubricJson = {
  'enabled': true,
  'criteria': [
    {'label': 'Makharij', 'maxPoints': 4},
    {'label': 'Madd length', 'maxPoints': 4},
    {'label': 'Fluency', 'maxPoints': 2},
  ],
};

void main() {
  group('learner side', () {
    test('part scores are read from the submission', () {
      final a = AssignmentModel.fromJson({
        'id': 'a1',
        'title': 'Recitation',
        'submission': {
          'status': 'graded',
          'grade': 7,
          'rubricScores': [
            {'label': 'Makharij', 'points': 3, 'maxPoints': 4},
            {'label': 'Fluency', 'points': 2, 'maxPoints': 2},
          ],
        },
      });
      expect(a.rubricScores.map((s) => s.scoreLabel), ['3 / 4', '2 / 2']);
    });

    test('work given one mark has no part scores', () {
      final a = AssignmentModel.fromJson({
        'id': 'a1',
        'title': 'x',
        'submission': {'grade': 8},
      });
      expect(a.rubricScores, isEmpty);
      expect(RubricScore.listFrom('bad'), isEmpty);
    });
  });

  group('faculty side', () {
    test('a rubric switched off marks with one number', () {
      expect(
        RubricSpec.fromJson({..._rubricJson, 'enabled': false}).isOn,
        isFalse,
      );
      expect(RubricSpec.fromJson(null).isOn, isFalse);
      final on = RubricSpec.fromJson(_rubricJson);
      expect(on.isOn, isTrue);
      expect(on.total, 10);
    });

    test('Save needs every part; the total adds up', () {
      final grade = RubricGradeProvider(
        rubric: RubricSpec.fromJson(_rubricJson),
        initialScores: const [
          RubricScore(label: 'Makharij', points: 3, maxPoints: 4),
        ],
      );
      expect(grade.scoreFor(0), 3);
      expect(grade.isComplete, isFalse);
      expect(grade.result, isNull);
      grade.setScore(1, 2);
      grade.setScore(2, 5); // over the part's maximum: not accepted
      expect(grade.scoreFor(2), isNull);
      grade.setScore(2, 2);
      grade.setFeedback(' Hold the madd longer ');
      expect(grade.total, 7);
      expect(grade.result!.points, [3, 2, 2]);
      expect(grade.result!.feedback, 'Hold the madd longer');
    });

    testWidgets('the dialog scores each part and returns the marks', (
      tester,
    ) async {
      RubricGradeResult? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await RubricGradeDialog.show(
                context,
                rubric: RubricSpec.fromJson(_rubricJson),
              ),
              child: const Text('mark'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('mark'));
      await tester.pumpAndSettle();
      expect(find.text('Mark Each Part'), findsOneWidget);
      final save = find.widgetWithText(FilledButton, 'Save');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      Future<void> pick(String part, String points) async {
        final chip = find.descendant(
          of: find
              .ancestor(of: find.text(part), matching: find.byType(Column))
              .first,
          matching: find.widgetWithText(ChoiceChip, points),
        );
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pump();
      }

      await pick('Makharij (out of 4)', '3');
      await pick('Madd length (out of 4)', '2');
      await pick('Fluency (out of 2)', '2');
      expect(find.text('Total: 7 / 10'), findsOneWidget);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(result!.points, [3, 2, 2]);
    });
  });
}
