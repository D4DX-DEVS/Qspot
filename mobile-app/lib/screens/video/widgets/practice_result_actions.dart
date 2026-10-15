import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/home_palette.dart';
import '../../quiz/screens/quiz_review_screen.dart';
import '../../quiz/widgets/answers_hidden_note.dart';
import '../../quiz/widgets/review_answers_button.dart';
import '../model/practice_result_summary.dart';

/// Under a practice score: tries so far, the answers (or when they will
/// show), and Try Again while practice is open.
class PracticeResultActions extends StatelessWidget {
  const PracticeResultActions({
    super.key,
    required this.summary,
    required this.locale,
    this.onRetake,
  });

  final PracticeResultSummary summary;
  final String locale;

  /// Null when the practice can't be taken again (closed, or no questions).
  final VoidCallback? onRetake;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final tries = summary.triesLine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tries != null) ...[
          Text(
            tries,
            textAlign: TextAlign.center,
            style: AppFonts.medium(color: p.textMuted, fontSize: 13),
          ),
          const SizedBox(height: AppTheme.paddingMedium),
        ],
        if (summary.canReview)
          ReviewAnswersButton(
            label: 'See Answers',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuizReviewScreen(
                  results: summary.reviewResults,
                  language: locale,
                ),
              ),
            ),
          )
        else
          AnswersHiddenNote(availability: summary.answers),
        if (onRetake != null) ...[
          const SizedBox(height: AppTheme.paddingMedium),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: onRetake,
              icon: const Icon(LucideIcons.rotateCcw),
              label: Text('Try Again', style: AppFonts.bold(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                foregroundColor: p.brand,
                side: BorderSide(color: p.brand, width: 1.5),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
