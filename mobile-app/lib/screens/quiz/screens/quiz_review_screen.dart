import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/accent_tone.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/state_message_view.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/common/tone_chip.dart';
import '../../common/widgets/home_theme_scope.dart';
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
    // Burgundy home theme; the page reads colours from the context inside it.
    return HomeThemeScope(child: Builder(builder: _buildPage));
  }

  Widget _buildPage(BuildContext context) {
    final p = HomePalette.of(context);
    return Scaffold(
      appBar: const CommonAppBar(title: 'Questions & Answers'),
      body: results.isEmpty
          ? const StateMessageView(
              icon: LucideIcons.listChecks,
              title: 'No Quiz Results Available',
              message:
                  'This attempt has no per-question breakdown to show yet.',
            )
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(
                AppTheme.contentInset,
                AppTheme.paddingSmall,
                AppTheme.contentInset,
                28 + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: results.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppTheme.paddingMedium,
                    ),
                    child: Text(
                      'Detailed analysis of each question',
                      style: AppFonts.regular(color: p.textMuted, fontSize: 14),
                    ),
                  );
                }
                return StaggeredEntrance(
                  index: index - 1,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppTheme.paddingMedium,
                    ),
                    child: _buildQuestionCard(p, results[index - 1], index),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildQuestionCard(
    HomePalette p,
    QuestionResult result,
    int questionNumber,
  ) {
    final questionText = result.getQuestion(language);
    final options = result.getOptions(language);
    final correctAnswerIndex = result.correctAnswer;
    final userAnswerIndex = result.attemptedAnswer;
    final isCorrect = result.isCorrect;
    final verdict = isCorrect ? p.mint : p.coral;

    return SurfaceCard(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      borderColor: verdict.color.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $questionNumber',
                style: AppFonts.medium(color: p.textMuted, fontSize: 13.5),
              ),
              ToneChip(
                label: isCorrect ? 'Correct' : 'Incorrect',
                tone: verdict,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingMedium),
          Text(
            questionText,
            style: AppFonts.semiBold(
              color: p.text,
              fontSize: 15.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppTheme.paddingMedium),
          Text(
            'Options',
            style: AppFonts.regular(color: p.textMuted, fontSize: 13),
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          // One column per option: the text wraps instead of overflowing on
          // a narrow phone or at a large text scale.
          for (final (optionIndex, option) in options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
              child: _optionRow(
                p,
                option,
                isCorrectOption: optionIndex == correctAnswerIndex,
                isWrongPick: optionIndex == userAnswerIndex && !isCorrect,
              ),
            ),
          const SizedBox(height: AppTheme.paddingSmall),
          _answerLine(
            p,
            'Correct answer',
            (correctAnswerIndex >= 0 && correctAnswerIndex < options.length)
                ? options[correctAnswerIndex]
                : '-',
            p.mint.color,
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          _answerLine(
            p,
            'Your answer',
            (userAnswerIndex != null &&
                    userAnswerIndex >= 0 &&
                    userAnswerIndex < options.length)
                ? options[userAnswerIndex]
                : 'Not answered',
            verdict.color,
          ),
        ],
      ),
    );
  }

  Widget _optionRow(
    HomePalette p,
    String option, {
    required bool isCorrectOption,
    required bool isWrongPick,
  }) {
    final AccentTone? tone = isCorrectOption
        ? p.mint
        : isWrongPick
        ? p.coral
        : null;
    final marked = tone != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone?.soft ?? p.brandSoft.withValues(alpha: p.isDark ? 1 : 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: tone?.color ?? p.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              option,
              style: marked
                  ? AppFonts.bold(color: tone.color, fontSize: 14)
                  : AppFonts.regular(color: p.text, fontSize: 14),
              softWrap: true,
            ),
          ),
          if (isCorrectOption)
            Icon(LucideIcons.check, color: p.mint.color, size: 18),
          if (isWrongPick) Icon(LucideIcons.x, color: p.coral.color, size: 18),
        ],
      ),
    );
  }

  Widget _answerLine(
    HomePalette p,
    String label,
    String value,
    Color valueColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppFonts.regular(color: p.textMuted, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppFonts.bold(color: valueColor, fontSize: 14),
          softWrap: true,
        ),
      ],
    );
  }
}
