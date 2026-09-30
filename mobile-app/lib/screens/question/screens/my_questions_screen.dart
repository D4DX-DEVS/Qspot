import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../model/user_question_model.dart';
import '../provider/my_questions_screen_provider.dart';
import 'ask_question_screen.dart';

class MyQuestionsScreen extends StatefulWidget {
  const MyQuestionsScreen({super.key});

  @override
  State<MyQuestionsScreen> createState() => _MyQuestionsScreenState();
}

class _MyQuestionsScreenState extends State<MyQuestionsScreen> {
  final MyQuestionsScreenProvider _state = MyQuestionsScreenProvider();

  @override
  void initState() {
    super.initState();
    _state.loadQuestions();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _state,
      child: Consumer<MyQuestionsScreenProvider>(
        builder: (_, state, __) => _buildPage(state),
      ),
    );
  }

  Widget _buildPage(MyQuestionsScreenProvider state) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        title: 'My questions',
        actions: [
          TextButton(
            onPressed: () async {
              await AskQuestionScreen.show(context);
              _state.loadQuestions();
            },
            child: Text(
              'Ask new',
              style: AppFonts.bold(color: AppColors.primary, fontSize: 15),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!state.isLoading && state.errorMessage == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _filterButton(
                      state,
                      'All',
                      state.filter == QuestionFilter.all,
                    ),
                    const SizedBox(width: 8),
                    _filterButton(
                      state,
                      'Answered',
                      state.filter == QuestionFilter.answered,
                    ),
                    const SizedBox(width: 8),
                    _filterButton(
                      state,
                      'Pending',
                      state.filter == QuestionFilter.pending,
                    ),
                  ],
                ),
              ),

            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : state.errorMessage != null
                  ? _buildErrorState(state)
                  : _buildQuestionsList(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(
    MyQuestionsScreenProvider state,
    String label,
    bool selected,
  ) {
    return InkWell(
      onTap: () => state.setFilter(switch (label) {
        'Answered' => QuestionFilter.answered,
        'Pending' => QuestionFilter.pending,
        _ => QuestionFilter.all,
      }),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppFonts.semiBold(
            color: selected ? AppColors.primary : AppColors.textMuted,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(MyQuestionsScreenProvider state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(
              'Could not load your questions',
              style: AppFonts.bold(color: AppColors.textPrimary, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              state.errorMessage ?? '',
              textAlign: TextAlign.center,
              style: AppFonts.regular(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: const StadiumBorder(),
              ),
              onPressed: _state.loadQuestions,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(MyQuestionsScreenProvider state) {
    final filtered = state.filter != QuestionFilter.all;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              filtered ? 'Nothing here' : 'There is nothing here yet',
              style: AppFonts.bold(color: AppColors.textPrimary, fontSize: 19),
            ),
            const SizedBox(height: 10),
            Text(
              filtered
                  ? 'No ${state.filter == QuestionFilter.answered ? 'answered' : 'pending'} questions so far.'
                  : 'Tap "Ask new" to ask your first question.',
              textAlign: TextAlign.center,
              style: AppFonts.regular(
                color: AppColors.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsList(MyQuestionsScreenProvider state) {
    final questions = state.filteredQuestions;
    if (questions.isEmpty) return _buildEmptyState(state);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _state.loadQuestions,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: questions.length,
        itemBuilder: (context, index) => _buildQuestionCard(questions[index]),
      ),
    );
  }

  Widget _buildQuestionCard(UserQuestion question) {
    final hasAnswer = question.answer != null && question.answer!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status chip, like the reference's timestamp pill.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: hasAnswer ? AppColors.primary : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              hasAnswer ? 'Answered' : 'Waiting for an answer',
              style: AppFonts.bold(
                color: hasAnswer ? AppColors.onPrimary : AppColors.textMuted,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            question.subject,
            style: AppFonts.bold(color: AppColors.primary, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            question.description,
            style: AppFonts.regular(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(question.createdAt),
            style: AppFonts.regular(color: AppColors.textMuted, fontSize: 12),
          ),
          if (hasAnswer) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.answer!,
                    style: AppFonts.regular(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Answered by ${question.answeredBy ?? 'the faculty'}'
                    '${question.answeredAt != null ? ' · ${_formatDate(question.answeredAt!)}' : ''}',
                    style: AppFonts.semiBold(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
