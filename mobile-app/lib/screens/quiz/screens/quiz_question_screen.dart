import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/api_client.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../provider/quiz_provider.dart';
import 'quiz_results_screen.dart';

/// Shows the active quiz session, one question at a time. The display
/// language is locked for the whole session (set before this screen was
/// pushed) — there is no in-quiz language toggle, since switching mid-quiz
/// previously corrupted submissions and could throw a RangeError on a
/// shorter/empty Malayalam options list.
class QuizQuestionScreen extends StatefulWidget {
  const QuizQuestionScreen({super.key});

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  bool _submitting = false;
  Timer? _timer;
  int? _remainingSeconds;
  bool _timerStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_timerStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startTimerIfConfigured(context.read<QuizProvider>());
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerIfConfigured(QuizProvider quizProvider) {
    if (_timerStarted || !quizProvider.isQuizActive) return;
    final mode = quizProvider.timerMode;
    final overall = mode == 'overall' || mode == 'both'
        ? quizProvider.overallTimeLimit
        : null;
    final perQuestion = mode == 'per-question' || mode == 'both'
        ? quizProvider.perQuestionTimeLimit
        : null;
    final initial = overall ?? perQuestion;
    if (initial == null || initial <= 0) return;
    _timerStarted = true;
    _remainingSeconds = initial;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _remainingSeconds == null) return;
      if (_remainingSeconds! <= 1) {
        _timer?.cancel();
        setState(() => _remainingSeconds = 0);
        _submit(quizProvider);
      } else {
        setState(() => _remainingSeconds = _remainingSeconds! - 1);
      }
    });
  }

  void _resetPerQuestionTimer(QuizProvider quizProvider) {
    if (!_timerStarted || quizProvider.timerMode == 'overall') return;
    final perQuestion = quizProvider.perQuestionTimeLimit;
    if (perQuestion != null && perQuestion > 0) {
      setState(() => _remainingSeconds = perQuestion);
    }
  }

  String _timerLabel() {
    final seconds = _remainingSeconds ?? 0;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, child) {
        final locale = quizProvider.sessionLanguage;
        final totalQuestions = quizProvider.totalQuestions;
        _startTimerIfConfigured(quizProvider);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CommonAppBar(
            title: totalQuestions > 0
                ? 'Question ${quizProvider.currentQuestionIndex + 1} of $totalQuestions'
                : quizProvider.quizTitle.isNotEmpty
                ? quizProvider.quizTitle
                : 'Quiz',
          ),
          body: totalQuestions == 0
              ? _buildEmptyState(context)
              : _buildQuestionBody(context, quizProvider, locale),
        );
      },
    );
  }

  /// Guards the 0-questions case (an empty `questions` array in the
  /// payload) instead of leaving the user on an infinite spinner.
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.quiz_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'No questions available',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              'This quiz has no questions right now. Please try again later.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingLarge),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionBody(
    BuildContext context,
    QuizProvider quizProvider,
    String locale,
  ) {
    final question = quizProvider.currentQuestion;
    if (question == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final selectedAnswer = quizProvider.getSelectedAnswer(question.id);
    final questionText = question.getQuestion(locale);
    final options = question.getOptions(locale);
    final currentIndex = quizProvider.currentQuestionIndex;
    final totalQuestions = quizProvider.totalQuestions;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingMedium,
            vertical: AppTheme.paddingSmall,
          ),
          child: LinearProgressIndicator(
            value: (currentIndex + 1) / totalQuestions,
            backgroundColor: AppColors.surfaceAlt,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.primary,
            ),
            minHeight: 4,
          ),
        ),
        if (_remainingSeconds != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _remainingSeconds! <= 10
                      ? AppColors.danger.withValues(alpha: 0.12)
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(
                    'Time ${_timerLabel()}',
                    style: AppFonts.bold(
                      color: _remainingSeconds! <= 10
                          ? AppColors.danger
                          : AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _difficultyColor(
                      question.difficulty,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _difficultyColor(question.difficulty),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    question.difficulty.toUpperCase(),
                    style: AppFonts.bold(
                      color: _difficultyColor(question.difficulty),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                Text(
                  questionText,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingLarge * 2),
                ...options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected = selectedAnswer == index;

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppTheme.paddingMedium,
                    ),
                    child: InkWell(
                      onTap: () => quizProvider.selectAnswer(index),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.paddingMedium),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.surfaceAlt,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: AppColors.onPrimary,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: AppTheme.paddingMedium),
                            Expanded(
                              child: Text(
                                option,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: isSelected
                                          ? AppColors.onPrimary
                                          : AppColors.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: const Border(top: BorderSide(color: AppColors.border)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: quizProvider.hasPreviousQuestion
                    ? () => quizProvider.previousQuestion()
                    : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingMedium,
                  ),
                  child: Row(
                    children: List.generate(totalQuestions, (index) {
                      final qId = quizProvider.sessionQuestions[index].id;
                      final answered =
                          quizProvider.getSelectedAnswer(qId) != null;
                      return GestureDetector(
                        onTap: () => quizProvider.goToQuestion(index),
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: index == currentIndex
                                ? AppColors.primary
                                : answered
                                ? AppColors.primarySoft
                                : AppColors.surfaceAlt,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: AppFonts.bold(
                                color: index == currentIndex
                                    ? AppColors.onPrimary
                                    : answered
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _submitting
                    ? null
                    : () {
                        if (quizProvider.hasNextQuestion) {
                          quizProvider.nextQuestion();
                          _resetPerQuestionTimer(quizProvider);
                        } else {
                          _showSubmitDialog(context, quizProvider);
                        }
                      },
                icon: Icon(
                  quizProvider.hasNextQuestion
                      ? Icons.arrow_forward
                      : Icons.check,
                ),
                label: Text(quizProvider.hasNextQuestion ? 'Next' : 'Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  void _showSubmitDialog(BuildContext context, QuizProvider quizProvider) {
    final answeredCount = quizProvider.answeredCount;
    final totalQuestions = quizProvider.totalQuestions;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          'Submit Quiz?',
          style: AppFonts.medium(color: AppColors.textPrimary),
        ),
        content: Text(
          'You have answered $answeredCount out of $totalQuestions questions.\n\nDo you want to submit the quiz?',
          style: AppFonts.regular(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppFonts.medium(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _submit(quizProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(QuizProvider quizProvider) async {
    setState(() => _submitting = true);
    final navigator = Navigator.of(context);

    try {
      final attempt = await quizProvider.submitQuiz();
      if (!mounted) return;
      // Only navigate to results after a genuine server confirmation
      // (201, or the 409-already-attempted case whose body still carries a
      // real attempt) — never speculatively.
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultsScreen.fromAttempt(
            attempt,
            onDone: () =>
                Navigator.of(navigator.context).popUntil((r) => r.isFirst),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: e.message, color: AppColors.danger);
      if (e.status == 403) {
        // Quiz is no longer live — route back to the quiz list.
        navigator.pop();
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'We couldn\'t submit your quiz. Please try again.',
        color: AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
