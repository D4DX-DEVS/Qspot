import 'package:flutter/material.dart';

import '../../../themes/app_theme.dart';
import '../model/quiz_model.dart';
import 'quiz_review_screen.dart';

/// Shows a quiz outcome. Renders strictly from server-provided fields —
/// never computed client-side — and is only ever shown after a genuine
/// `201` submission (or the `409`-already-attempted case, whose body also
/// carries a real `attempt`), or when opened from a list entry's
/// `myAttempt` summary.
class QuizResultsScreen extends StatelessWidget {
  final String title;
  final int score;
  final int totalQuestions;
  final num percentage;
  final DateTime? completedAt;

  /// Full per-question results, when available (a fresh submission has
  /// these; a `myAttempt` summary from the quiz list does not).
  final List<QuestionResult> results;
  final String language;
  final VoidCallback? onDone;

  const QuizResultsScreen({
    super.key,
    required this.title,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.completedAt,
    required this.results,
    this.language = 'en',
    this.onDone,
  });

  factory QuizResultsScreen.fromAttempt(
    QuizAttemptResult attempt, {
    VoidCallback? onDone,
  }) {
    return QuizResultsScreen(
      title: attempt.title,
      score: attempt.score,
      totalQuestions: attempt.totalQuestions,
      percentage: attempt.percentage,
      completedAt: attempt.createdAt,
      results: attempt.results,
      // attempt.language is the server's literal ('English'/'Malayalam'),
      // but [language] here is consumed as a locale code ('en'/'ml') by
      // QuestionResult.getQuestion/getOptions — translate it, otherwise a
      // Malayalam attempt would always render its review in English.
      language: attempt.language == 'Malayalam' ? 'ml' : 'en',
      onDone: onDone,
    );
  }

  int get _correctCount =>
      results.isNotEmpty ? results.where((r) => r.isCorrect).length : score;

  int get _wrongCount => totalQuestions - _correctCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Quiz Results',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        automaticallyImplyLeading: onDone == null,
        leading: onDone != null
            ? IconButton(icon: const Icon(Icons.close), onPressed: onDone)
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.paddingLarge * 2),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _scoreIcon(percentage),
                    size: 80,
                    color: AppTheme.primaryWhite,
                  ),
                  const SizedBox(height: AppTheme.paddingMedium),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryWhite.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.paddingSmall),
                  Text(
                    '${percentage.toStringAsFixed(percentage % 1 == 0 ? 0 : 1)}%',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.primaryWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingSmall),
                  Text(
                    _scoreText(percentage),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primaryWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.paddingLarge * 2),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    context,
                    'Total',
                    totalQuestions.toString(),
                    Icons.help_outline,
                  ),
                ),
                const SizedBox(width: AppTheme.paddingMedium),
                Expanded(
                  child: _statCard(
                    context,
                    'Correct',
                    _correctCount.toString(),
                    Icons.check_circle,
                    AppTheme.success,
                  ),
                ),
                const SizedBox(width: AppTheme.paddingMedium),
                Expanded(
                  child: _statCard(
                    context,
                    'Wrong',
                    _wrongCount.toString(),
                    Icons.cancel,
                    AppTheme.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingLarge * 2),
            if (results.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizReviewScreen(
                          results: results,
                          language: language,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text(
                    'Review Answers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppTheme.paddingLarge),
            if (completedAt != null)
              Text(
                'Completed on ${_formatDateTime(completedAt!)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryGray),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    IconData icon, [
    Color? iconColor,
  ]) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor ?? AppTheme.primary, size: 32),
          const SizedBox(height: AppTheme.paddingSmall),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryGray),
          ),
        ],
      ),
    );
  }

  IconData _scoreIcon(num pct) {
    if (pct >= 90) return Icons.emoji_events;
    if (pct >= 70) return Icons.star;
    if (pct >= 50) return Icons.thumb_up;
    return Icons.school;
  }

  String _scoreText(num pct) {
    if (pct >= 90) return 'Excellent!';
    if (pct >= 70) return 'Good!';
    if (pct >= 50) return 'Average';
    return 'Keep Practicing!';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
