import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/accent_tone.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/confetti_burst.dart';
import '../../../widgets/animation/count_up_text.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/gradient_card.dart';
import '../../../widgets/common/surface_card.dart';
import '../../certificate/widgets/view_certificate_button.dart';
import '../../common/widgets/home_theme_scope.dart';
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

  /// When set, a "View Certificate" button shows once a certificate has
  /// been issued for this quiz.
  final String? quizId;

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
    this.quizId,
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
      quizId: attempt.quizId,
    );
  }

  int get _correctCount =>
      results.isNotEmpty ? results.where((r) => r.isCorrect).length : score;

  int get _wrongCount => totalQuestions - _correctCount;

  // Same cut-off as the "Good!" message and star icon below.
  bool get _scoredWell => percentage >= 70;

  @override
  Widget build(BuildContext context) {
    // Burgundy home theme; the page reads colours from the context inside it.
    return HomeThemeScope(child: Builder(builder: _buildPage));
  }

  Widget _buildPage(BuildContext context) {
    final p = HomePalette.of(context);
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Quiz Results',
        leading: onDone != null
            ? IconButton(icon: const Icon(LucideIcons.x), onPressed: onDone)
            : null,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppTheme.contentInset,
              AppTheme.paddingSmall,
              AppTheme.contentInset,
              28 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              children: [
                StaggeredEntrance(child: _heroCard(context)),
                const SizedBox(height: AppTheme.sectionGap),
                _statRow(context, p),
                const SizedBox(height: AppTheme.sectionGap),
                if (results.isNotEmpty) _reviewButton(context, p),
                if (quizId != null)
                  ViewCertificateButton(
                    quizId: quizId!,
                    padding: EdgeInsets.only(
                      top: results.isNotEmpty ? AppTheme.paddingMedium : 0,
                    ),
                  ),
                const SizedBox(height: AppTheme.paddingLarge),
                if (completedAt != null)
                  StaggeredEntrance(
                    index: 5,
                    child: Text(
                      'Completed on ${_formatDateTime(completedAt!)}',
                      style: AppFonts.regular(color: p.textMuted, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          if (_scoredWell) const Positioned.fill(child: ConfettiBurst()),
        ],
      ),
    );
  }

  Widget _heroCard(BuildContext context) {
    return GradientCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingLarge,
        vertical: AppTheme.paddingLarge * 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(_scoreIcon(percentage), size: 72, color: AppColors.white),
          const SizedBox(height: AppTheme.paddingMedium),
          Text(
            title,
            style: AppFonts.medium(color: AppColors.white70, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          CountUpText(
            '${percentage.toStringAsFixed(percentage % 1 == 0 ? 0 : 1)}%',
            style: AppFonts.extraBold(color: AppColors.white, fontSize: 44),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _scoreText(percentage),
            style: AppFonts.bold(color: AppColors.white, fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context, HomePalette p) {
    // IntrinsicHeight so the three cards share one height whatever their
    // labels wrap to; a bare `stretch` would ask for infinite height inside
    // the scroll view.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StaggeredEntrance(
              index: 1,
              child: _statCard(
                p,
                'Total',
                totalQuestions.toString(),
                LucideIcons.circleQuestionMark,
                p.rose,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.paddingMedium),
          Expanded(
            child: StaggeredEntrance(
              index: 2,
              child: _statCard(
                p,
                'Correct',
                _correctCount.toString(),
                LucideIcons.circleCheck,
                p.mint,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.paddingMedium),
          Expanded(
            child: StaggeredEntrance(
              index: 3,
              child: _statCard(
                p,
                'To Revisit',
                _wrongCount.toString(),
                LucideIcons.rotateCcw,
                p.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewButton(BuildContext context, HomePalette p) {
    return StaggeredEntrance(
      index: 4,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: PressableScale(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      QuizReviewScreen(results: results, language: language),
                ),
              );
            },
            icon: const Icon(LucideIcons.eye),
            label: Text('Review Answers', style: AppFonts.bold(fontSize: 16)),
            style: OutlinedButton.styleFrom(
              foregroundColor: p.brand,
              side: BorderSide(color: p.brand, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    HomePalette p,
    String label,
    String value,
    IconData icon,
    AccentTone tone,
  ) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingSmall,
        vertical: AppTheme.paddingMedium,
      ),
      child: Column(
        children: [
          Icon(icon, color: tone.color, size: 30),
          const SizedBox(height: AppTheme.paddingSmall),
          CountUpText(
            value,
            style: AppFonts.extraBold(color: p.text, fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppFonts.regular(color: p.textMuted, fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _scoreIcon(num pct) {
    if (pct >= 90) return LucideIcons.trophy;
    if (pct >= 70) return LucideIcons.star;
    if (pct >= 50) return LucideIcons.thumbsUp;
    return LucideIcons.graduationCap;
  }

  String _scoreText(num pct) {
    if (pct >= 90) return 'Crushed It!';
    if (pct >= 70) return 'Nice Work!';
    if (pct >= 50) return 'Almost There!';
    return "Good Start, Let's Level Up!";
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
