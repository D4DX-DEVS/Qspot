import 'package:flutter/material.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/common_app_bar.dart';
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
      backgroundColor: AppColors.background,
      appBar: const CommonAppBar(title: 'Questions & Answers'),
      body: results.isEmpty
          ? Center(
              child: Text(
                'No quiz results available',
                style: AppFonts.regular(color: AppColors.textPrimary),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.paddingLarge),
                  color: AppColors.background,
                  child: Text(
                    'Detailed analysis of each question',
                    style: AppFonts.regular(
                      color: AppColors.textMuted,
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
            ? AppColors.success.withValues(alpha: 0.07)
            : AppColors.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isCorrect
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.danger.withValues(alpha: 0.3),
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
                  style: AppFonts.medium(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCorrect ? Icons.check : Icons.close,
                        color: isCorrect ? AppColors.success : AppColors.danger,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCorrect ? 'Correct' : 'Incorrect',
                        style: AppFonts.bold(
                          color: isCorrect
                              ? AppColors.success
                              : AppColors.danger,
                          fontSize: 12,
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
              style: AppFonts.medium(
                color: AppColors.textPrimary,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'Options:',
              style: AppFonts.regular(color: AppColors.textMuted, fontSize: 14),
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
                  backgroundColor = AppColors.success.withValues(alpha: 0.12);
                  borderColor = AppColors.success;
                  textColor = AppColors.success;
                } else if (showIncorrectMark) {
                  backgroundColor = AppColors.danger.withValues(alpha: 0.12);
                  borderColor = AppColors.danger;
                  textColor = AppColors.danger;
                } else {
                  backgroundColor = AppColors.surfaceAlt;
                  borderColor = AppColors.border;
                  textColor = AppColors.textPrimary;
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
                          style: (showCorrectMark || showIncorrectMark)
                              ? AppFonts.bold(color: textColor, fontSize: 14)
                              : AppFonts.regular(
                                  color: textColor,
                                  fontSize: 14,
                                ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ),
                      if (showCorrectMark)
                        Icon(Icons.check, color: AppColors.success, size: 18),
                      if (showIncorrectMark)
                        Icon(Icons.close, color: AppColors.danger, size: 18),
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
                      Text(
                        'Correct Answer:',
                        style: AppFonts.regular(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (correctAnswerIndex >= 0 &&
                                correctAnswerIndex < options.length)
                            ? options[correctAnswerIndex]
                            : '-',
                        style: AppFonts.bold(
                          color: AppColors.success,
                          fontSize: 14,
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
                      Text(
                        "User's Answer:",
                        style: AppFonts.regular(
                          color: AppColors.textMuted,
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
                        style: AppFonts.bold(
                          color: isCorrect
                              ? AppColors.success
                              : AppColors.danger,
                          fontSize: 14,
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
