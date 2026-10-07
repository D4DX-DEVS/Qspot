import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../services/api_client.dart';
import '../../../themes/accent_tone.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/animated_progress_bar.dart';
import '../../../widgets/animation/fade_on_change.dart';
import '../../../widgets/animation/pop_on_change.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/state_message_view.dart';
import '../../../widgets/common/tone_chip.dart';
import '../../common/widgets/home_theme_scope.dart';
import '../provider/quiz_provider.dart';
import '../provider/quiz_question_screen_provider.dart';
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
  final QuizQuestionScreenProvider _q = QuizQuestionScreenProvider();
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_q.timerStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startTimerIfConfigured(context.read<QuizProvider>());
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _startTimerIfConfigured(QuizProvider quizProvider) {
    if (_q.timerStarted || !quizProvider.isQuizActive) return;
    final mode = quizProvider.timerMode;
    final overall = mode == 'overall' || mode == 'both'
        ? quizProvider.overallTimeLimit
        : null;
    final perQuestion = mode == 'per-question' || mode == 'both'
        ? quizProvider.perQuestionTimeLimit
        : null;
    final initial = overall ?? perQuestion;
    if (initial == null || initial <= 0) return;
    _q.startTimer(initial);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _q.remainingSeconds;
      if (!mounted || remaining == null) return;
      if (remaining <= 1) {
        _timer?.cancel();
        _q.setRemainingSeconds(0);
        _submit(quizProvider);
      } else {
        _q.setRemainingSeconds(remaining - 1);
      }
    });
  }

  void _resetPerQuestionTimer(QuizProvider quizProvider) {
    if (!_q.timerStarted || quizProvider.timerMode == 'overall') return;
    final perQuestion = quizProvider.perQuestionTimeLimit;
    if (perQuestion != null && perQuestion > 0) {
      _q.setRemainingSeconds(perQuestion);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Burgundy home theme; the page reads colours from the context inside it.
    return HomeThemeScope(
      child: ChangeNotifierProvider.value(
        value: _q,
        child: Consumer<QuizQuestionScreenProvider>(
          builder: (_, q, __) => _buildPage(q),
        ),
      ),
    );
  }

  Widget _buildPage(QuizQuestionScreenProvider q) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, child) {
        final locale = quizProvider.sessionLanguage;
        final totalQuestions = quizProvider.totalQuestions;
        _startTimerIfConfigured(quizProvider);

        return Scaffold(
          appBar: CommonAppBar(
            title: totalQuestions > 0
                ? 'Question ${quizProvider.currentQuestionIndex + 1} of $totalQuestions'
                : quizProvider.quizTitle.isNotEmpty
                ? quizProvider.quizTitle
                : 'Quiz',
          ),
          body: totalQuestions == 0
              // Guards the 0-questions case (an empty `questions` array in
              // the payload) instead of leaving the user on an infinite
              // spinner; the app bar's back arrow takes them out.
              ? const StateMessageView(
                  icon: LucideIcons.listChecks,
                  title: 'No Questions Available',
                  message:
                      'This quiz has no questions right now. Please try again later.',
                )
              : _buildQuestionBody(context, quizProvider, locale, q),
        );
      },
    );
  }

  Widget _buildQuestionBody(
    BuildContext context,
    QuizProvider quizProvider,
    String locale,
    QuizQuestionScreenProvider q,
  ) {
    final p = HomePalette.of(context);
    final question = quizProvider.currentQuestion;
    if (question == null) {
      return Center(child: CircularProgressIndicator(color: p.brand));
    }

    final selectedAnswer = quizProvider.getSelectedAnswer(question.id);
    final questionText = question.getQuestion(locale);
    final options = question.getOptions(locale);
    final currentIndex = quizProvider.currentQuestionIndex;
    final totalQuestions = quizProvider.totalQuestions;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.contentInset,
            vertical: AppTheme.paddingSmall,
          ),
          child: AnimatedProgressBar(
            value: (currentIndex + 1) / totalQuestions,
            backgroundColor: p.brandSoft,
            color: p.brand,
            minHeight: 4,
          ),
        ),
        if (q.remainingSeconds != null) _timerChip(p, q),
        Expanded(
          child: FadeOnChange(
            trigger: question.id,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.contentInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _difficultyChip(p, question.difficulty),
                  const SizedBox(height: AppTheme.paddingLarge),
                  Text(
                    questionText,
                    style: AppFonts.bold(
                      color: p.text,
                      fontSize: 20,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppTheme.sectionGap),
                  for (final (index, option) in options.indexed)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.paddingMedium,
                      ),
                      child: _optionTile(
                        p,
                        option: option,
                        isSelected: selectedAnswer == index,
                        popKey: ValueKey('${question.id}-$index'),
                        onTap: () => quizProvider.selectAnswer(index),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        _bottomBar(context, p, quizProvider, q, currentIndex, totalQuestions),
      ],
    );
  }

  /// Countdown pill, right-aligned above the question. Turns to the warning
  /// tone in the last ten seconds.
  Widget _timerChip(HomePalette p, QuizQuestionScreenProvider q) {
    final tone = q.remainingSeconds! <= 10 ? p.coral : p.rose;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.contentInset,
        4,
        AppTheme.contentInset,
        0,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: ToneChip(label: 'Time ${q.timerLabel}', tone: tone),
      ),
    );
  }

  Widget _difficultyChip(HomePalette p, String difficulty) {
    final tone = _difficultyTone(p, difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.color.withValues(alpha: 0.5)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: AppFonts.bold(color: tone.color, fontSize: 12),
      ),
    );
  }

  Widget _optionTile(
    HomePalette p, {
    required String option,
    required bool isSelected,
    required Key popKey,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      child: Material(
        color: isSelected ? p.brand : p.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: BorderSide(
            color: isSelected ? p.brand : p.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            child: Row(
              children: [
                PopOnChange(
                  key: popKey,
                  active: isSelected,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.white24 : p.brandSoft,
                      border: Border.all(
                        color: isSelected ? AppColors.white : p.cardBorder,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            LucideIcons.check,
                            size: 15,
                            color: AppColors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: AppTheme.paddingMedium),
                Expanded(
                  child: Text(
                    option,
                    style: isSelected
                        ? AppFonts.semiBold(
                            color: AppColors.white,
                            fontSize: 16,
                          )
                        : AppFonts.regular(color: p.text, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(
    BuildContext context,
    HomePalette p,
    QuizProvider quizProvider,
    QuizQuestionScreenProvider q,
    int currentIndex,
    int totalQuestions,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTheme.paddingMedium,
        AppTheme.paddingMedium,
        AppTheme.paddingMedium,
        AppTheme.paddingMedium + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: p.background,
        border: Border(top: BorderSide(color: p.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: p.isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PressableScale(
            enabled: quizProvider.hasPreviousQuestion,
            child: ElevatedButton.icon(
              onPressed: quizProvider.hasPreviousQuestion
                  ? () => quizProvider.previousQuestion()
                  : null,
              icon: const Icon(LucideIcons.arrowLeft),
              label: const Text('Previous'),
              style: ElevatedButton.styleFrom(
                backgroundColor: p.card,
                foregroundColor: p.brand,
                side: BorderSide(color: p.cardBorder),
              ),
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
                  final answered = quizProvider.getSelectedAnswer(qId) != null;
                  return _questionDot(
                    p,
                    number: index + 1,
                    isCurrent: index == currentIndex,
                    answered: answered,
                    onTap: () => quizProvider.goToQuestion(index),
                  );
                }),
              ),
            ),
          ),
          PressableScale(
            enabled: !q.submitting,
            child: ElevatedButton.icon(
              onPressed: q.submitting
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
                    ? LucideIcons.arrowRight
                    : LucideIcons.check,
              ),
              label: Text(quizProvider.hasNextQuestion ? 'Next' : 'Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: p.brand,
                foregroundColor: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionDot(
    HomePalette p, {
    required int number,
    required bool isCurrent,
    required bool answered,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      pressedScale: 0.88,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isCurrent
                ? p.brand
                : answered
                ? p.brandSoft
                : p.cardBorder,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: AppFonts.bold(
                color: isCurrent
                    ? AppColors.white
                    : answered
                    ? p.brand
                    : p.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  AccentTone _difficultyTone(HomePalette p, String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return p.mint;
      case 'medium':
        return p.amber;
      case 'hard':
        return p.coral;
      default:
        return p.slate;
    }
  }

  void _showSubmitDialog(BuildContext context, QuizProvider quizProvider) {
    final p = HomePalette.of(context);
    final answeredCount = quizProvider.answeredCount;
    final totalQuestions = quizProvider.totalQuestions;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: p.card,
        title: Text(
          'Submit Quiz?',
          style: AppFonts.bold(color: p.text, fontSize: 18),
        ),
        content: Text(
          'You have answered $answeredCount out of $totalQuestions questions.\n\nDo you want to submit the quiz?',
          style: AppFonts.regular(
            color: p.textMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: AppFonts.medium(color: p.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _submit(quizProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: p.brand,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(QuizProvider quizProvider) async {
    _q.setSubmitting(true);
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
      if (mounted) _q.setSubmitting(false);
    }
  }
}
