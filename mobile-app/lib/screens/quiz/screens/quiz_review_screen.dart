import 'package:flutter/material.dart';

import '../../../themes/app_theme.dart';
import '../model/quiz_model.dart';

/// Per-question review, rendered strictly from server-graded
/// [QuestionResult]s — no client-side correctness computation.
class QuizReviewScreen extends StatelessWidget {
  final List<QuestionResult> results;
  final String language;

  const QuizReviewScreen({
    super.key,
    required this.results,
    this.language = 'en',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Questions & Answers',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: results.isEmpty
          ? const Center(
              child: Text(
                'No quiz results available',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.paddingLarge),
                  color: AppTheme.background,
                  child: const Text(
                    'Detailed analysis of each question',
                    style: TextStyle(
                      color: AppTheme.secondaryGray,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.paddingMedium),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      return _buildQuestionCard(
                        context,
                        results[index],
                        index + 1,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    QuestionResult result,
    int questionNumber,
  ) {
    final questionText = result.getQuestion(language);
    final options = result.getOptions(language);
    final correctAnswerIndex = result.correctAnswer;
    final userAnswerIndex = result.attemptedAnswer;
    final isCorrect = result.isCorrect;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingLarge),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppTheme.success.withValues(alpha: 0.07)
            : AppTheme.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isCorrect
              ? AppTheme.success.withValues(alpha: 0.3)
              : AppTheme.danger.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question $questionNumber',
                  style: const TextStyle(
                    color: AppTheme.secondaryGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? AppTheme.success.withValues(alpha: 0.12)
                        : AppTheme.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCorrect ? Icons.check : Icons.close,
                        color: isCorrect ? AppTheme.success : AppTheme.danger,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCorrect ? 'Correct' : 'Incorrect',
                        style: TextStyle(
                          color: isCorrect ? AppTheme.success : AppTheme.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              questionText,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            const Text(
              'Options:',
              style: TextStyle(color: AppTheme.secondaryGray, fontSize: 14),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: AppTheme.paddingSmall,
                mainAxisSpacing: AppTheme.paddingSmall,
              ),
              itemCount: options.length,
              itemBuilder: (context, optionIndex) {
                final isCorrectOption = optionIndex == correctAnswerIndex;
                final isUserOption = optionIndex == userAnswerIndex;
                final showCorrectMark = isCorrectOption;
                final showIncorrectMark = isUserOption && !isCorrect;

                Color backgroundColor;
                Color borderColor;
                Color textColor;

                if (isCorrectOption) {
                  backgroundColor = AppTheme.success.withValues(alpha: 0.12);
                  borderColor = AppTheme.success;
                  textColor = AppTheme.success;
                } else if (showIncorrectMark) {
                  backgroundColor = AppTheme.danger.withValues(alpha: 0.12);
                  borderColor = AppTheme.danger;
                  textColor = AppTheme.danger;
                } else {
                  backgroundColor = AppTheme.surfaceAlt;
                  borderColor = AppTheme.border;
                  textColor = AppTheme.textPrimary;
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          options[optionIndex],
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: (showCorrectMark || showIncorrectMark)
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ),
                      if (showCorrectMark)
                        Icon(Icons.check, color: AppTheme.success, size: 18),
                      if (showIncorrectMark)
                        Icon(Icons.close, color: AppTheme.danger, size: 18),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Correct Answer:',
                        style: TextStyle(
                          color: AppTheme.secondaryGray,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (correctAnswerIndex >= 0 &&
                                correctAnswerIndex < options.length)
                            ? options[correctAnswerIndex]
                            : '-',
                        style: const TextStyle(
                          color: AppTheme.success,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "User's Answer:",
                        style: TextStyle(
                          color: AppTheme.secondaryGray,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (userAnswerIndex != null &&
                                userAnswerIndex >= 0 &&
                                userAnswerIndex < options.length)
                            ? options[userAnswerIndex]
                            : 'Not answered',
                        style: TextStyle(
                          color: isCorrect ? AppTheme.success : AppTheme.danger,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
