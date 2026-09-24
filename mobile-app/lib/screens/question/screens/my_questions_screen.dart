import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../themes/app_theme.dart';
import '../../auth/service/auth_service.dart';
import '../../../utils/api_urls.dart';
import 'ask_question_screen.dart';

enum _QuestionFilter { all, answered, pending }

class MyQuestionsScreen extends StatefulWidget {
  const MyQuestionsScreen({super.key});

  @override
  State<MyQuestionsScreen> createState() => _MyQuestionsScreenState();
}

class _MyQuestionsScreenState extends State<MyQuestionsScreen> {
  List<UserQuestion> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;
  _QuestionFilter _filter = _QuestionFilter.all;

  List<UserQuestion> get _filteredQuestions {
    switch (_filter) {
      case _QuestionFilter.answered:
        return _questions
            .where((q) => q.answer != null && q.answer!.isNotEmpty)
            .toList();
      case _QuestionFilter.pending:
        return _questions
            .where((q) => q.answer == null || q.answer!.isEmpty)
            .toList();
      case _QuestionFilter.all:
        return _questions;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();
      final token = await authService.getSavedToken();

      if (token == null || token.isEmpty) {
        throw Exception('Please login to view your questions');
      }

      final uri = Uri.parse('${ApiUrls.baseUrl}/api/user/my-questions');

      debugPrint('📝 [MY QUESTIONS] Fetching from: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📝 [MY QUESTIONS] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);

        setState(() {
          _questions = jsonResponse
              .map((json) => UserQuestion.fromJson(json))
              .toList();
          _isLoading = false;
        });

        debugPrint('📝 [MY QUESTIONS] Loaded ${_questions.length} questions');
      } else {
        throw Exception('Failed to load questions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('📝 [MY QUESTIONS] Error: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Close on the left, centred title, "Ask new" on the right.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'My questions',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        await AskQuestionScreen.show(context);
                        _loadQuestions();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Ask new',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (!_isLoading && _errorMessage == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _filterButton('All', _filter == _QuestionFilter.all),
                    const SizedBox(width: 8),
                    _filterButton(
                      'Answered',
                      _filter == _QuestionFilter.answered,
                    ),
                    const SizedBox(width: 8),
                    _filterButton(
                      'Pending',
                      _filter == _QuestionFilter.pending,
                    ),
                  ],
                ),
              ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _errorMessage != null
                  ? _buildErrorState()
                  : _buildQuestionsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(String label, bool selected) {
    return InkWell(
      onTap: () => setState(() {
        _filter = switch (label) {
          'Answered' => _QuestionFilter.answered,
          'Pending' => _QuestionFilter.pending,
          _ => _QuestionFilter.all,
        };
      }),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primarySoft : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.primary : AppTheme.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 14),
            const Text(
              'Could not load your questions',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.onPrimary,
                shape: const StadiumBorder(),
              ),
              onPressed: _loadQuestions,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final filtered = _filter != _QuestionFilter.all;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 48,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              filtered ? 'Nothing here' : 'There is nothing here yet',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              filtered
                  ? 'No ${_filter == _QuestionFilter.answered ? 'answered' : 'pending'} questions so far.'
                  : 'Tap "Ask new" to ask your first question.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsList() {
    final questions = _filteredQuestions;
    if (questions.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadQuestions,
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
              color: hasAnswer ? AppTheme.primary : AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              hasAnswer ? 'Answered' : 'Waiting for an answer',
              style: TextStyle(
                color: hasAnswer ? AppTheme.onPrimary : AppTheme.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            question.subject,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            question.description,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(question.createdAt),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          if (hasAnswer) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.answer!,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Answered by ${question.answeredBy ?? 'the faculty'}'
                    '${question.answeredAt != null ? ' · ${_formatDate(question.answeredAt!)}' : ''}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

// Model for User Question with Answer
class UserQuestion {
  final String id;
  final String subject;
  final String description;
  final String facultyId;
  final String facultyName;
  final String? facultyDesignation;
  final String userId;
  final String userName;
  final String? userClass;
  final String? answer;
  final String? answeredBy;
  final DateTime? answeredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserQuestion({
    required this.id,
    required this.subject,
    required this.description,
    required this.facultyId,
    required this.facultyName,
    this.facultyDesignation,
    required this.userId,
    required this.userName,
    this.userClass,
    this.answer,
    this.answeredBy,
    this.answeredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserQuestion.fromJson(Map<String, dynamic> json) {
    final faculty = json['faculty'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;

    return UserQuestion(
      id: json['_id']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      facultyId: faculty?['_id']?.toString() ?? '',
      facultyName: faculty?['name']?.toString() ?? 'Unknown Faculty',
      facultyDesignation: faculty?['designation']?.toString(),
      userId: user?['_id']?.toString() ?? '',
      userName: user?['name']?.toString() ?? 'Unknown User',
      userClass: user?['class']?.toString(),
      answer: json['answer']?.toString(),
      answeredBy: json['answeredBy']?.toString(),
      answeredAt: json['answeredAt'] != null
          ? DateTime.parse(json['answeredAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}
