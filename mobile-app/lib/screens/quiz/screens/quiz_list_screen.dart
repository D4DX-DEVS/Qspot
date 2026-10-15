import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../services/api_client.dart';
import '../../../services/quiz_reminder_service.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/info_note_card.dart';
import '../../../widgets/common/loading_skeleton.dart';
import '../../../widgets/common/notice_sheet.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/state_message_view.dart';
import '../../common/widgets/home_theme_scope.dart';
import '../model/quiz_model.dart';
import '../model/quiz_progress_record.dart';
import '../model/quiz_refusal.dart';
import '../provider/quiz_provider.dart';
import '../widgets/quiz_language_dialog.dart';
import '../widgets/quiz_list_card.dart';
import '../widgets/quiz_offline_continue_list.dart';
import '../widgets/quiz_pending_banner.dart';
import '../widgets/quiz_refused_banner.dart';
import '../widgets/quiz_reminder_permission_dialog.dart';
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
    if (quiz.isEnded) {
      NoticeSheet.show(
        context,
        icon: LucideIcons.calendarX,
        title: "You Didn't Attempt This Quiz",
        message:
            'This quiz ended before you took it, so there is no score to show. '
            "Keep an eye on Live Now so you don't miss the next one.",
      );
      return;
    }
    if (quiz.isUpcoming) {
      final start = quiz.startDate;
      NoticeSheet.show(
        context,
        icon: LucideIcons.calendarClock,
        tone: (p) => p.amber,
        title: "This Quiz Hasn't Started Yet",
        message: start == null
            ? 'Come back once it goes live to take it.'
            : 'It opens on ${start.day}/${start.month}/${start.year}. '
                  'Come back then to take it.',
      );
      return;
    }
    if (!quiz.isLive) return;
    final quizProvider = context.read<QuizProvider>();
    if (quizProvider.isWaitingToSend(quiz.id)) {
      // Submitted already: final, not reopened. Try sending it again.
      AppSnackBar.show(
        context,
        message: QuizProvider.submittedWaitingMessage,
        color: AppColors.warningOrange,
      );
      unawaited(quizProvider.fetchQuizList());
      return;
    }
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
          quizId: quiz.id,
          answersRevealed: attempt.answersRevealed,
          answersAvailableAt: attempt.answersAvailableAt,
          attemptId: attempt.attemptId.isEmpty ? null : attempt.attemptId,
        ),
      ),
    );
  }

  Future<void> _startQuiz(QuizListItem quiz) async {
    final language = await QuizLanguageDialog.show(context);
    if (language == null || !mounted) return;
    // First quiz only: offer the "quiz closes soon" reminder.
    await QuizReminderService.askPermissionOnce(() async {
      if (!mounted) return false;
      return QuizReminderPermissionDialog.show(context);
    });
    if (!mounted) return;
    await _openQuiz(quiz.id, language);
  }

  /// Carries on with a quiz started on this phone, in the language it was
  /// started in. Works offline from the saved copy.
  Future<void> _continueQuiz(QuizProgressRecord quiz) =>
      _openQuiz(quiz.quizId, quiz.language);

  Future<void> _openQuiz(String quizId, String language) async {
    final quizProvider = context.read<QuizProvider>();
    try {
      await quizProvider.startQuiz(quizId, language: language);
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
                if (quizProvider.hasListError &&
                    quizProvider.inProgressQuizzes.isNotEmpty) {
                  return QuizOfflineContinueList(
                    quizzes: quizProvider.inProgressQuizzes,
                    onContinue: _continueQuiz,
                    onRetry: quizProvider.fetchQuizList,
                  );
                }
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
                  child: _buildList(context, quizProvider),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, QuizProvider quizProvider) {
    final quizzes = quizProvider.quizList;
    final pending = quizProvider.pendingSubmissions;
    final refused = quizProvider.refusedSubmissions;
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
        for (final record in refused)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: QuizRefusedBanner(
              message: QuizRefusal.message(record),
              onDismiss: () => quizProvider.dismissRefused(record.quizId),
              onReopen: _retakeAction(quizProvider, record),
            ),
          ),
        if (pending.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: QuizPendingBanner(
              message: _pendingMessage(pending),
              sending: quizProvider.isFlushing,
              onSend: quizProvider.fetchQuizList,
            ),
          ),
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

  String _pendingMessage(List<QuizProgressRecord> pending) {
    final what = pending.length == 1
        ? (pending.single.title.isEmpty
              ? 'your quiz'
              : '"${pending.single.title}"')
        : '${pending.length} quizzes';
    return 'Your answers for $what are saved on this phone but have not been '
        'sent yet. They will be sent when you are back online.';
  }

  /// "Open Quiz Again" for answers refused because the questions changed,
  /// while the quiz is still open to take: the old copy goes and the quiz
  /// starts afresh with the new questions.
  VoidCallback? _retakeAction(
    QuizProvider quizProvider,
    QuizProgressRecord record,
  ) {
    if (!record.canRetake) return null;
    final quiz = quizProvider.quizList
        .where((q) => q.id == record.quizId && q.isLive && !q.hasAttempted)
        .firstOrNull;
    if (quiz == null) return null;
    return () async {
      await quizProvider.dismissRefused(record.quizId);
      if (mounted) await _startQuiz(quiz);
    };
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
