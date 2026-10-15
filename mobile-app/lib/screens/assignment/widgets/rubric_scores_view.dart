import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../model/rubric_score.dart';

/// The score for each part, under the teacher's feedback, for work marked
/// by parts.
class RubricScoresView extends StatelessWidget {
  const RubricScoresView({super.key, required this.scores});

  final List<RubricScore> scores;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final score in scores)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    score.label,
                    style: AppFonts.regular(color: p.text, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  score.scoreLabel,
                  style: AppFonts.bold(
                    color: score.points >= score.maxPoints
                        ? p.mint.color
                        : p.text,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
