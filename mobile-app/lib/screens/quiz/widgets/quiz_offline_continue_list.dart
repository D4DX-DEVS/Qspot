import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_theme.dart';
import '../../../widgets/common/offline_notice.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/soft_outline_button.dart';
import '../model/quiz_progress_record.dart';
import 'quiz_continue_card.dart';

/// Shown instead of the quiz list when it cannot be loaded but quizzes the
/// student started are saved on this phone: they can carry on offline.
class QuizOfflineContinueList extends StatelessWidget {
  const QuizOfflineContinueList({
    super.key,
    required this.quizzes,
    required this.onContinue,
    required this.onRetry,
  });

  final List<QuizProgressRecord> quizzes;
  final ValueChanged<QuizProgressRecord> onContinue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppTheme.contentInset,
        8,
        AppTheme.contentInset,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        const OfflineNotice(
          message:
              "Can't load quizzes right now. You can carry on with a quiz "
              'you started; your answers are saved on this phone.',
        ),
        const SizedBox(height: 8),
        const SectionHeader(title: 'Continue Your Quiz'),
        const SizedBox(height: 4),
        for (final quiz in quizzes)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: QuizContinueCard(
              title: quiz.title,
              answered: quiz.answeredCount,
              total: quiz.questionIds.length,
              onTap: () => onContinue(quiz),
            ),
          ),
        const SizedBox(height: 8),
        Center(
          child: SoftOutlineButton(
            label: 'Try Again',
            icon: LucideIcons.refreshCw,
            onPressed: onRetry,
          ),
        ),
      ],
    );
  }
}
