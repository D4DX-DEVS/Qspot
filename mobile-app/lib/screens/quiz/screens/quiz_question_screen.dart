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
  // Each number dot is [_dotSize] wide with [_dotGap] margin on both sides.
  static const double _dotSize = 32;
  static const double _dotGap = 4;

  final QuizQuestionScreenProvider _q = QuizQuestionScreenProvider();
  final ScrollController _dotsController = ScrollController();
  late QuizProvider _quizProvider;
  Timer? _timer;
  int? _dotsScrolledFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _quizProvider = context.read<QuizProvider>();
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
    _dotsController.dispose();
    // The session is over once this screen goes (submitted, timed out or
    // left). Deferred: listeners can't be notified while the tree is being
    // torn down.
    Future.microtask(_quizProvider.resetSession);
    super.dispose();
  }

  void _startTimerIfConfigured(QuizProvider quizProvider) {
    if (_q.timerStarted || !quizProvider.isQuizActive) return;
    final overall = quizProvider.hasOverallTimer
        ? quizProvider.overallTimeLimit
        : null;
    final perQuestion = quizProvider.hasPerQuestionTimer
        ? quizProvider.perQuestionTimeLimit
        : null;
    if (overall == null && perQuestion == null) return;
    _q.startTimers(overall: overall, perQuestion: perQuestion);
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onTick(quizProvider),
    );
  }

  void _onTick(QuizProvider quizProvider) {
    // Paused while a submit is in flight, so it can't fire a second one.
    if (!mounted || _q.submitting) return;
    switch (_q.tick()) {
      case QuizTimerExpiry.overall:
        _submit(quizProvider);
      case QuizTimerExpiry.question:
        // Time's up for this question: move on keeping whatever answer is
        // selected (none stays unanswered), or submit after the last one.
        if (quizProvider.hasNextQuestion) {
          quizProvider.nextQuestion();
          _q.resetQuestionTimer();
        } else {
          _submit(quizProvider);
        }
      case QuizTimerExpiry.none:
        break;
    }
  }

  /// Brings the current question's number dot into view (centred) when it
  /// sits outside the visible part of the strip. Runs once per question
  /// change, so timer rebuilds don't undo a manual scroll of the strip.
  void _revealCurrentDot(int index) {
    if (_dotsScrolledFor == index) return;
    _dotsScrolledFor = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_dotsController.hasClients) return;
      final position = _dotsController.position;
      const extent = _dotSize + _dotGap * 2;
      final start = AppTheme.paddingMedium + index * extent;
      final end = start + extent;
      final visibleEnd = position.pixels + position.viewportDimension;
      if (start >= position.pixels && end <= visibleEnd) return;
      final target = (start + extent / 2 - position.viewportDimension / 2)
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      _dotsController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
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
        if (q.overallRemaining != null || q.questionRemaining != null)
          _timerChips(p, q),
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

  /// Countdown pills, right-aligned above the question: the whole-quiz time
  /// and/or this question's time. Each turns to the warning tone in its last
  /// ten seconds.
  Widget _timerChips(HomePalette p, QuizQuestionScreenProvider q) {
    final overall = q.overallRemaining;
    final question = q.questionRemaining;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.contentInset,
        4,
        AppTheme.contentInset,
        0,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: AppTheme.paddingSmall,
          runSpacing: 4,
          children: [
            if (overall != null) _timerChip(p, 'Time', overall),
            if (question != null) _timerChip(p, 'This question', question),
          ],
        ),
      ),
    );
  }

  Widget _timerChip(HomePalette p, String label, int seconds) => ToneChip(
    label: '$label ${QuizQuestionScreenProvider.timerLabel(seconds)}',
    tone: seconds <= 10 ? p.coral : p.rose,
  );

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
    _revealCurrentDot(currentIndex);
    // A per-question timer makes the quiz one-way: no Previous and no
    // jumping between numbers (jumping ahead would skip questions for good).
    final freeNavigation = !quizProvider.hasPerQuestionTimer;
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
          if (freeNavigation)
            PressableScale(
              enabled: quizProvider.hasPreviousQuestion,
              child: ElevatedButton(
                onPressed: quizProvider.hasPreviousQuestion
                    ? () => quizProvider.previousQuestion()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.card,
                  foregroundColor: p.brand,
                  side: BorderSide(color: p.cardBorder),
                  padding: const EdgeInsets.all(12),
                  minimumSize: const Size.square(48),
                ),
                child: const Icon(
                  LucideIcons.arrowLeft,
                  semanticLabel: 'Previous',
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              controller: _dotsController,
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
                    onTap: freeNavigation
                        ? () => quizProvider.goToQuestion(index)
                        : null,
                  );
                }),
              ),
            ),
          ),
          PressableScale(
            enabled: !q.submitting,
            child: ElevatedButton(
              onPressed: q.submitting
                  ? null
                  : () {
                      if (quizProvider.hasNextQuestion) {
                        quizProvider.nextQuestion();
                        _q.resetQuestionTimer();
                      } else {
                        _showSubmitDialog(context, quizProvider);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: p.brand,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.all(12),
                minimumSize: const Size.square(48),
              ),
              child: Icon(
                quizProvider.hasNextQuestion
                    ? LucideIcons.arrowRight
                    : LucideIcons.check,
                semanticLabel: quizProvider.hasNextQuestion ? 'Next' : 'Submit',
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
    required VoidCallback? onTap,
  }) {
    return PressableScale(
      enabled: onTap != null,
      pressedScale: 0.88,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: _dotSize,
          height: _dotSize,
          margin: const EdgeInsets.symmetric(horizontal: _dotGap),
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
    // The timer and the dialog can both trigger a submit; only the first
    // one goes through.
    if (_q.submitting) return;
    _q.setSubmitting(true);
    final navigator = Navigator.of(context);
    final route = ModalRoute.of(context)!;
    // A timed-out submit can fire while the "Submit Quiz?" dialog is open.
    // Close it so the results replace this screen, not the dialog.
    navigator.popUntil((r) => r == route);

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
            // Back to the quiz list, same as the system back button.
            onDone: () => navigator.pop(),
          ),
        ),
      );
      // Stays "submitting" while this screen leaves, so the timer can't
      // fire another submit during the transition.
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: e.message, color: AppColors.danger);
      if (e.status == 403) {
        // Quiz is no longer live — route back to the quiz list.
        navigator.pop();
      } else {
        _q.setSubmitting(false);
      }
    } catch (e) {
      if (!mounted) return;
      _q.setSubmitting(false);
      AppSnackBar.show(
        context,
        message: 'We couldn\'t submit your quiz. Please try again.',
        color: AppColors.danger,
      );
    }
  }
}
