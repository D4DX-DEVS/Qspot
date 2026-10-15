import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_colors.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../provider/quiz_attempt_review_provider.dart';
import '../screens/quiz_review_screen.dart';
import 'review_answers_button.dart';

/// "Review Answers" for a result that arrived without its answers (opened
/// from the quiz list): loads the attempt, then opens the review.
class QuizReviewLoaderButton extends StatelessWidget {
  const QuizReviewLoaderButton({super.key, required this.attemptId});

  final String attemptId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizAttemptReviewProvider(),
      child: Consumer<QuizAttemptReviewProvider>(
        builder: (context, review, _) => ReviewAnswersButton(
          loading: review.loading,
          onPressed: () => _open(context, review),
        ),
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    QuizAttemptReviewProvider review,
  ) async {
    final attempt = await review.load(attemptId);
    if (!context.mounted) return;
    if (attempt == null) {
      AppSnackBar.show(
        context,
        message: review.error ?? "Couldn't load your answers.",
        color: AppColors.danger,
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizReviewScreen(
          results: attempt.results,
          language: attempt.language == 'Malayalam' ? 'ml' : 'en',
        ),
      ),
    );
  }
}
