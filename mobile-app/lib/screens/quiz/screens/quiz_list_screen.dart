import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../services/api_client.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/info_note_card.dart';
import '../../../widgets/common/loading_skeleton.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/state_message_view.dart';
import '../../common/widgets/home_theme_scope.dart';
import '../model/quiz_model.dart';
import '../provider/quiz_provider.dart';
import '../widgets/quiz_language_dialog.dart';
import '../widgets/quiz_list_card.dart';
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
    final language = await QuizLanguageDialog.show(context);
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

  @override
  Widget build(BuildContext context) {
    // Burgundy home theme; the page reads colours from the context inside it.
    return HomeThemeScope(
      child: Builder(
        builder: (context) {
          final p = HomePalette.of(context);
          return Scaffold(
            appBar: const CommonAppBar(title: 'Quiz'),
            body: Consumer<QuizProvider>(
              builder: (context, quizProvider, child) {
                if (quizProvider.isListLoading) return const LoadingSkeleton();
                if (quizProvider.hasListError) {
                  return StateMessageView(
                    icon: LucideIcons.circleAlert,
                    title: 'Error Loading Quizzes',
                    message: quizProvider.listError,
                    onRetry: quizProvider.fetchQuizList,
                  );
                }
                return RefreshIndicator(
                  onRefresh: quizProvider.fetchQuizList,
                  backgroundColor: p.card,
                  color: p.brand,
                  child: _buildList(context, quizProvider.quizList),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<QuizListItem> quizzes) {
    final live = quizzes.where((q) => q.isLive).toList();
    final upcoming = quizzes.where((q) => q.isUpcoming).toList();
    final ended = quizzes.where((q) => q.isEnded).toList();
    final p = HomePalette.of(context);

    // Always render a clear "No live quiz" state instead of hiding the
    // screen: the empty array is an expected, normal response.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppTheme.contentInset,
        8,
        AppTheme.contentInset,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (live.isEmpty)
          StaggeredEntrance(
            child: InfoNoteCard(
              icon: LucideIcons.listChecks,
              tone: p.amber,
              message:
                  'No live quiz right now. Check back later, or see upcoming and past quizzes below.',
            ),
          )
        else
          ..._section('Live Now', live),
        if (upcoming.isNotEmpty) ..._section('Upcoming', upcoming),
        if (ended.isNotEmpty) ..._section('Ended', ended),
      ],
    );
  }

  List<Widget> _section(String title, List<QuizListItem> quizzes) => [
    const SizedBox(height: 8),
    SectionHeader(title: title),
    const SizedBox(height: 4),
    for (final (index, quiz) in quizzes.indexed)
      StaggeredEntrance(
        index: index,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: QuizListCard(quiz: quiz, onTap: () => _onQuizTap(quiz)),
        ),
      ),
  ];
}
