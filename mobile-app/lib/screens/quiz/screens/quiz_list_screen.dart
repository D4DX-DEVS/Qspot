import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/api_client.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../model/quiz_model.dart';
import '../provider/quiz_provider.dart';
import 'quiz_question_screen.dart';
import 'quiz_results_screen.dart';

/// Entry point for the quiz feature (Option B: live-quiz-list).
///
/// Always renders something sensible: a "No live quiz" informational state
/// when the list is empty or has no live entries, upcoming quizzes with
/// their start date, and ended/attempted quizzes with the user's score.
class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().fetchQuizList();
    });
  }

  Future<void> _onQuizTap(QuizListItem quiz) async {
    if (quiz.hasAttempted) {
      _showAttemptSummary(quiz);
      return;
    }
    if (!quiz.isLive) return;
    await _startQuiz(quiz);
  }

  void _showAttemptSummary(QuizListItem quiz) {
    final attempt = quiz.myAttempt!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) => QuizResultsScreen(
          title: quiz.title,
          score: attempt.score,
          totalQuestions: attempt.totalQuestions,
          percentage: attempt.percentage,
          completedAt: attempt.createdAt,
          results: const [],
          onDone: () => Navigator.pop(routeContext),
        ),
      ),
    );
  }

  Future<void> _startQuiz(QuizListItem quiz) async {
    final language = await _pickLanguage();
    if (language == null || !mounted) return;

    final quizProvider = context.read<QuizProvider>();
    try {
      await quizProvider.startQuiz(quiz.id, language: language);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuizQuestionScreen()),
      );
      if (mounted) {
        quizProvider.fetchQuizList();
      }
    } on ApiException catch (e) {
      if (e.status == 409) {
        // Already attempted — refresh the list so myAttempt shows up and
        // the user can see their existing result instead of an error.
        await quizProvider.fetchQuizList();
      }
      if (!mounted) return;
      if (e.status == 409) {
        AppSnackBar.show(
          context,
          message: 'You\'ve already taken this quiz',
          color: AppColors.warningOrange,
        );
      } else {
        AppSnackBar.show(context, message: e.message, color: AppColors.danger);
      }
    }
  }

  Future<String?> _pickLanguage() {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Quiz Language',
                style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This cannot be changed once the quiz starts.',
                style: Theme.of(
                  dialogContext,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _languageButton(
                      dialogContext,
                      'English',
                      () => Navigator.pop(dialogContext, 'en'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _languageButton(
                      dialogContext,
                      'മലയാളം',
                      () => Navigator.pop(dialogContext, 'ml'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.transparent,
          shadowColor: AppColors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CommonAppBar(title: 'Quiz'),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          if (quizProvider.isListLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (quizProvider.hasListError) {
            return _buildErrorState(context, quizProvider);
          }

          return RefreshIndicator(
            onRefresh: quizProvider.fetchQuizList,
            color: AppColors.primary,
            child: _buildList(context, quizProvider.quizList),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, QuizProvider quizProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'Error Loading Quizzes',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              quizProvider.listError,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingLarge),
            ElevatedButton(
              onPressed: quizProvider.fetchQuizList,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<QuizListItem> quizzes) {
    final live = quizzes.where((q) => q.isLive).toList();
    final upcoming = quizzes.where((q) => q.isUpcoming).toList();
    final ended = quizzes.where((q) => q.isEnded).toList();

    if (live.isEmpty) {
      // Always render a clear "No live quiz" state instead of hiding the
      // screen — the empty array is an expected, normal response.
      return ListView(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        children: [
          _buildNoLiveQuizCard(context),
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: AppTheme.paddingLarge),
            _sectionHeader(context, 'Upcoming'),
            ...upcoming.map((q) => _quizCard(context, q)),
          ],
          if (ended.isNotEmpty) ...[
            const SizedBox(height: AppTheme.paddingLarge),
            _sectionHeader(context, 'Ended'),
            ...ended.map((q) => _quizCard(context, q)),
          ],
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      children: [
        _sectionHeader(context, 'Live now'),
        ...live.map((q) => _quizCard(context, q)),
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: AppTheme.paddingLarge),
          _sectionHeader(context, 'Upcoming'),
          ...upcoming.map((q) => _quizCard(context, q)),
        ],
        if (ended.isNotEmpty) ...[
          const SizedBox(height: AppTheme.paddingLarge),
          _sectionHeader(context, 'Ended'),
          ...ended.map((q) => _quizCard(context, q)),
        ],
      ],
    );
  }

  Widget _buildNoLiveQuizCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.quiz_outlined, size: 56, color: AppColors.textMuted),
          const SizedBox(height: AppTheme.paddingMedium),
          Text(
            'No live quiz right now',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Text(
            'Check back later, or see upcoming and past quizzes below.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _quizCard(BuildContext context, QuizListItem quiz) {
    final attempt = quiz.myAttempt;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      child: InkWell(
        onTap: () => _onQuizTap(quiz),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: _statusColor(quiz), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quiz.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _statusBadge(context, quiz),
                ],
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              Text(
                quiz.assessmentType == 'practical'
                    ? 'Practical exam'
                    : 'Knowledge quiz',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
              ),
              Text(
                '${quiz.questionCount} question${quiz.questionCount == 1 ? '' : 's'}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
              if (quiz.isUpcoming && quiz.startDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Starts ${_formatDate(quiz.startDate!)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
              if (attempt != null) ...[
                const SizedBox(height: AppTheme.paddingSmall),
                Text(
                  'Your score: ${attempt.score}/${attempt.totalQuestions} (${attempt.percentage}%)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(QuizListItem quiz) {
    if (quiz.isLive) return AppColors.success;
    if (quiz.isUpcoming) return AppColors.warning;
    return AppColors.border;
  }

  Widget _statusBadge(BuildContext context, QuizListItem quiz) {
    final label = quiz.hasAttempted
        ? 'Attempted'
        : quiz.isLive
        ? 'Live'
        : quiz.isUpcoming
        ? 'Upcoming'
        : 'Ended';
    final color = quiz.hasAttempted ? AppColors.primary : _statusColor(quiz);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppFonts.bold(color: color, fontSize: 11)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
