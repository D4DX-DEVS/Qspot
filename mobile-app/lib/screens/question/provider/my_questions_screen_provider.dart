import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../utils/api_urls.dart';
import '../../auth/service/auth_service.dart';
import '../model/user_question_model.dart';
import '../../../utils/user_friendly_error.dart';

enum QuestionFilter { all, answered, pending }

/// Screen-local state for "My questions": the loaded list, its loading and
/// error state, the selected filter, and the fetch that fills them.
class MyQuestionsScreenProvider extends ChangeNotifier {
  List<UserQuestion> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;
  QuestionFilter _filter = QuestionFilter.all;
  bool _disposed = false;

  List<UserQuestion> get questions => _questions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  QuestionFilter get filter => _filter;

  List<UserQuestion> get filteredQuestions {
    switch (_filter) {
      case QuestionFilter.answered:
        return _questions
            .where((q) => q.answer != null && q.answer!.isNotEmpty)
            .toList();
      case QuestionFilter.pending:
        return _questions
            .where((q) => q.answer == null || q.answer!.isEmpty)
            .toList();
      case QuestionFilter.all:
        return _questions;
    }
  }

  void setFilter(QuestionFilter value) {
    _filter = value;
    notifyListeners();
  }

  Future<void> loadQuestions() async {
    _isLoading = true;
    _errorMessage = null;
    _notify();

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

        _questions = jsonResponse
            .map((json) => UserQuestion.fromJson(json))
            .toList();
        _isLoading = false;
        _notify();

        debugPrint('📝 [MY QUESTIONS] Loaded ${_questions.length} questions');
      } else {
        throw Exception('Failed to load questions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('📝 [MY QUESTIONS] Error: $e');
      _errorMessage = userFriendlyError(e);
      _isLoading = false;
      _notify();
    }
  }

  // The screen may close while a request is in flight.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
