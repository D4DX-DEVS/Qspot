import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/api_client.dart';
import '../../../themes/app_theme.dart';
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
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Text(
              totalQuestions > 0
                  ? 'Question ${quizProvider.currentQuestionIndex + 1} of $totalQuestions'
                  : quizProvider.quizTitle.isNotEmpty
                  ? quizProvider.quizTitle
                  : 'Quiz',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
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
              color: AppTheme.secondaryGray,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'No questions available',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              'This quiz has no questions right now. Please try again later.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingLarge),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gradientStart,
                foregroundColor: AppTheme.onPrimary,
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
        child: CircularProgressIndicator(color: AppTheme.gradientEnd),
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
            backgroundColor: AppTheme.surfaceAlt,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.gradientEnd,
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
                      ? AppTheme.danger.withValues(alpha: 0.12)
                      : AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(
                    'Time ${_timerLabel()}',
                    style: TextStyle(
                      color: _remainingSeconds! <= 10
                          ? AppTheme.danger
                          : AppTheme.primary,
                      fontWeight: FontWeight.w700,
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
                    style: TextStyle(
                      color: _difficultyColor(question.difficulty),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.paddingLarge),
                Text(
                  questionText,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
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
                              ? AppTheme.gradientStart
                              : AppTheme.background,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.gradientEnd
                                : AppTheme.border,
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
                                    ? AppTheme.gradientEnd
                                    : AppTheme.surfaceAlt,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: AppTheme.primaryWhite,
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
                                          ? AppTheme.onPrimary
                                          : AppTheme.textPrimary,
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
            color: AppTheme.background,
            border: const Border(top: BorderSide(color: AppTheme.border)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
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
                  backgroundColor: AppTheme.background,
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.border),
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
                                ? AppTheme.gradientEnd
                                : answered
                                ? AppTheme.primarySoft
                                : AppTheme.surfaceAlt,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: index == currentIndex
                                    ? AppTheme.onPrimary
                                    : answered
                                    ? AppTheme.primary
                                    : AppTheme.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
                  backgroundColor: AppTheme.gradientStart,
                  foregroundColor: AppTheme.onPrimary,
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
        return AppTheme.success;
      case 'medium':
        return AppTheme.warning;
      case 'hard':
        return AppTheme.danger;
      default:
        return AppTheme.textMuted;
    }
  }

  void _showSubmitDialog(BuildContext context, QuizProvider quizProvider) {
    final answeredCount = quizProvider.answeredCount;
    final totalQuestions = quizProvider.totalQuestions;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text(
          'Submit Quiz?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'You have answered $answeredCount out of $totalQuestions questions.\n\nDo you want to submit the quiz?',
          style: const TextStyle(color: AppTheme.secondaryGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.secondaryGray),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _submit(quizProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gradientStart,
              foregroundColor: AppTheme.onPrimary,
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.message)));
      if (e.status == 403) {
        // Quiz is no longer live — route back to the quiz list.
        navigator.pop();
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Failed to submit quiz')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
