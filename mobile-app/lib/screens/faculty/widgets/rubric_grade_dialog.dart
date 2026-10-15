import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../assignment/model/rubric_score.dart';
import '../model/rubric_grade_result.dart';
import '../model/rubric_spec.dart';
import '../provider/rubric_grade_provider.dart';
import 'rubric_part_scorer.dart';

/// Marking work part by part: a score for each part, the total, feedback.
class RubricGradeDialog extends StatelessWidget {
  const RubricGradeDialog({super.key});

  /// The scores and feedback, or null when cancelled.
  static Future<RubricGradeResult?> show(
    BuildContext context, {
    required RubricSpec rubric,
    List<RubricScore> initialScores = const [],
    String feedback = '',
  }) => showDialog<RubricGradeResult>(
    context: context,
    builder: (_) => ChangeNotifierProvider(
      create: (_) => RubricGradeProvider(
        rubric: rubric,
        initialScores: initialScores,
        feedback: feedback,
      ),
      child: const RubricGradeDialog(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final grade = context.watch<RubricGradeProvider>();
    final parts = grade.rubric.parts;
    return AlertDialog(
      title: const Text('Mark Each Part'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < parts.length; i++) ...[
              RubricPartScorer(
                part: parts[i],
                score: grade.scoreFor(i),
                onScore: (value) => grade.setScore(i, value),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              'Total: ${grade.total} / ${grade.rubric.total}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextFormField(
              initialValue: grade.feedback,
              maxLines: 3,
              maxLength: 10000,
              decoration: const InputDecoration(labelText: 'Feedback'),
              onChanged: grade.setFeedback,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: grade.isComplete
              ? () => Navigator.pop(context, grade.result)
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
