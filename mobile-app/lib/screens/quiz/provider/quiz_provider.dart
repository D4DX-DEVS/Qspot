import 'package:flutter/foundation.dart';

import '../../../services/api_client.dart';
import '../model/quiz_model.dart';

enum QuizLoadingState { idle, loading, loaded, error }

/// State management for the live-quiz-list ("Option B") flow.
///
/// All grading is server-side: this provider never computes correctness or
/// a score itself — it only renders what the server returns from
/// `POST /api/quizzes/attempt` (or the `myAttempt` summary from the list
/// endpoints).
class QuizProvider with ChangeNotifier {
  // ---- Quiz list ----
  QuizLoadingState _listState = QuizLoadingState.idle;
  String _listError = '';
  List<QuizListItem> _quizList = [];

  QuizLoadingState get listState => _listState;
  String get listError => _listError;
  List<QuizListItem> get quizList => _quizList;
  bool get isListLoading => _listState == QuizLoadingState.loading;
  bool get hasListError => _listState == QuizLoadingState.error;

  /// `GET /api/user-quizzes`. An empty result is a normal, expected state
  /// (no live quiz right now) — not an error.
  Future<void> fetchQuizList() async {
    _listState = QuizLoadingState.loading;
    _listError = '';
    notifyListeners();

    try {
      final data = await ApiClient.get('/api/user-quizzes');
      _quizList = (data as List<dynamic>? ?? [])
          .map((e) => QuizListItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _listState = QuizLoadingState.loaded;
    } on ApiException catch (e) {
      _listState = QuizLoadingState.error;
      _listError = e.message;
    } catch (e) {
      _listState = QuizLoadingState.error;
      _listError = 'Failed to load quizzes';
    }
    notifyListeners();
  }

  // ---- Quiz history (feeds Profile, per contract) ----
  QuizLoadingState _historyState = QuizLoadingState.idle;
  String _historyError = '';
  List<QuizHistoryItem> _quizHistory = [];

  QuizLoadingState get historyState => _historyState;
  String get historyError => _historyError;
  List<QuizHistoryItem> get quizHistory => _quizHistory;
  bool get isHistoryLoading => _historyState == QuizLoadingState.loading;

  /// `GET /api/user/quiz-attempts`. Intended for a "My Quiz History"
  /// screen/section — the Profile screen (owned separately) can call this
  /// and read [quizHistory].
  Future<void> fetchQuizHistory() async {
    _historyState = QuizLoadingState.loading;
    _historyError = '';
    notifyListeners();

    try {
      final data = await ApiClient.get('/api/user/quiz-attempts');
      _quizHistory = (data as List<dynamic>? ?? [])
          .map((e) => QuizHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _historyState = QuizLoadingState.loaded;
    } on ApiException catch (e) {
      _historyState = QuizLoadingState.error;
      _historyError = e.message;
    } catch (e) {
      _historyState = QuizLoadingState.error;
      _historyError = 'Failed to load quiz history';
    }
    notifyListeners();
  }

  // ---- Active quiz session ----
  QuizLoadingState _sessionState = QuizLoadingState.idle;
  String _sessionError = '';
  String? _quizId;
  String _quizTitle = '';
  int? _overallTimeLimit;
  int? _perQuestionTimeLimit;
  String _timerMode = 'none';
  List<QuizQuestion> _sessionQuestions = [];
  int _currentQuestionIndex = 0;

  /// Locked at [startQuiz] time and never changed mid-quiz — fixes the bug
  /// where toggling locale mid-quiz corrupted submission / could throw a
  /// RangeError on a shorter ML options list.
  String _sessionLanguage = 'en';

  /// questionId (String) -> selected option index, or null if unanswered.
  final Map<String, int?> _answers = {};
  DateTime? _quizStartTime;

  QuizLoadingState get sessionState => _sessionState;
  String get sessionError => _sessionError;
  bool get isSessionLoading => _sessionState == QuizLoadingState.loading;
  bool get hasSessionError => _sessionState == QuizLoadingState.error;

  String? get quizId => _quizId;
  String get quizTitle => _quizTitle;
  int? get overallTimeLimit => _overallTimeLimit;
  int? get perQuestionTimeLimit => _perQuestionTimeLimit;
  String get timerMode => _timerMode;
  List<QuizQuestion> get sessionQuestions => _sessionQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get totalQuestions => _sessionQuestions.length;
  String get sessionLanguage => _sessionLanguage;
  bool get isQuizActive =>
      _sessionState == QuizLoadingState.loaded && _sessionQuestions.isNotEmpty;

  QuizQuestion? get currentQuestion =>
      _currentQuestionIndex >= 0 &&
          _currentQuestionIndex < _sessionQuestions.length
      ? _sessionQuestions[_currentQuestionIndex]
      : null;

  bool get hasNextQuestion =>
      _currentQuestionIndex < _sessionQuestions.length - 1;
  bool get hasPreviousQuestion => _currentQuestionIndex > 0;

  int? getSelectedAnswer(String questionId) => _answers[questionId];

  int get answeredCount => _answers.values.where((v) => v != null).length;

  /// Sets the language the quiz will be taken in. Only has an effect before
  /// [startQuiz] is called — the language is locked for the whole session
  /// once a quiz has started (call this before, not during, a quiz).
  void setSessionLanguage(String locale) {
    if (isQuizActive) return; // locked mid-quiz
    _sessionLanguage = locale;
    notifyListeners();
  }

  /// `GET /api/user-quizzes/:id/questions`. Idempotent server-side: repeat
  /// calls for the same in-progress attempt return the same pinned question
  /// set. Throws [ApiException] with status 409 ("Already attempted") or
  /// 403 (quiz not currently live) — callers should catch and show
  /// `e.message`.
  Future<void> startQuiz(String quizId, {String? language}) async {
    _sessionState = QuizLoadingState.loading;
    _sessionError = '';
    _quizId = quizId;
    if (language != null) _sessionLanguage = language;
    notifyListeners();

    try {
      final data =
          await ApiClient.get('/api/user-quizzes/$quizId/questions')
              as Map<String, dynamic>;
      _applySessionData(data);
    } on ApiException catch (e) {
      _sessionState = QuizLoadingState.error;
      _sessionError = e.message;
      rethrow;
    } catch (e) {
      _sessionState = QuizLoadingState.error;
      _sessionError = 'Failed to load quiz questions';
    }
    notifyListeners();
  }

  void _applySessionData(Map<String, dynamic> data) {
    _quizTitle = data['title'] as String? ?? '';
    _overallTimeLimit = (data['overallTimeLimit'] as num?)?.toInt();
    _perQuestionTimeLimit = (data['perQuestionTimeLimit'] as num?)?.toInt();
    _timerMode = data['timerMode'] as String? ?? 'none';
    _sessionQuestions = (data['questions'] as List<dynamic>? ?? [])
        .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
        .toList();

    _currentQuestionIndex = 0;
    _answers.clear();
    for (final q in _sessionQuestions) {
      _answers[q.id] = null;
    }
    _quizStartTime = DateTime.now();
    _lastAttempt = null;
    _sessionState = QuizLoadingState.loaded;
  }

  /// Test-only seam: seeds an active session directly from raw question
  /// JSON (the same shape `GET /api/user-quizzes/:id/questions` returns),
  /// without making a network call. Lets unit tests exercise answer
  /// selection and payload building through the same code path production
  /// uses, without a fake HTTP layer.
  @visibleForTesting
  void seedSessionForTest(
    List<Map<String, dynamic>> questionsJson, {
    String? quizId,
  }) {
    _quizId = quizId ?? 'test-quiz';
    _applySessionData({'title': 'Test Quiz', 'questions': questionsJson});
  }

  void selectAnswer(int answerIndex) {
    final question = currentQuestion;
    if (question == null) return;
    _answers[question.id] = answerIndex;
    notifyListeners();
  }

  void nextQuestion() {
    if (hasNextQuestion) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (hasPreviousQuestion) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < _sessionQuestions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  // ---- Submission ----
  QuizAttemptResult? _lastAttempt;
  QuizAttemptResult? get lastAttempt => _lastAttempt;

  /// `POST /api/quizzes/attempt`. On success (`201`) or a `409`
  /// already-attempted response (whose body still carries the existing
  /// `attempt`), this sets [lastAttempt] and returns it so the caller can
  /// navigate to a results screen. On any other error the [ApiException]
  /// propagates for the caller to display (e.g. 403 quiz-not-live).
  Future<QuizAttemptResult> submitQuiz() async {
    if (_quizId == null || _sessionQuestions.isEmpty) {
      throw StateError('No active quiz session to submit');
    }

    final totalDuration = _quizStartTime == null
        ? 0
        : DateTime.now().difference(_quizStartTime!).inSeconds;

    final answers = _sessionQuestions
        .map((q) => {'questionId': q.id, 'attemptedAnswer': _answers[q.id]})
        .toList();

    final body = {
      'quizId': _quizId,
      // The server only recognizes the literal 'Malayalam' (anything else
      // is stored as 'English') — translate the locale code before sending
      // so the stored attempt.language matches what was actually taken.
      'language': _sessionLanguage == 'ml' ? 'Malayalam' : 'English',
      'answers': answers,
      'totalDuration': totalDuration,
    };

    try {
      final data =
          await ApiClient.post('/api/quizzes/attempt', body: body)
              as Map<String, dynamic>;
      final attempt = QuizAttemptResult.fromJson(
        data['attempt'] as Map<String, dynamic>,
      );
      _lastAttempt = attempt;
      notifyListeners();
      return attempt;
    } on ApiException catch (e) {
      if (e.status == 409 &&
          e.body is Map &&
          (e.body as Map)['attempt'] is Map<String, dynamic>) {
        // Already attempted — treat as success and show the existing
        // attempt's results rather than an error.
        final attempt = QuizAttemptResult.fromJson(
          (e.body as Map)['attempt'] as Map<String, dynamic>,
        );
        _lastAttempt = attempt;
        notifyListeners();
        return attempt;
      }
      rethrow;
    }
  }

  /// Builds the raw answers payload (exposed for tests without making a
  /// network call).
  List<Map<String, dynamic>> buildAnswersPayload() {
    return _sessionQuestions
        .map((q) => {'questionId': q.id, 'attemptedAnswer': _answers[q.id]})
        .toList();
  }

  /// Resets the active session (e.g. leaving the quiz screen).
  void resetSession() {
    _quizId = null;
    _quizTitle = '';
    _overallTimeLimit = null;
    _perQuestionTimeLimit = null;
    _timerMode = 'none';
    _sessionQuestions = [];
    _currentQuestionIndex = 0;
    _answers.clear();
    _quizStartTime = null;
    _lastAttempt = null;
    _sessionState = QuizLoadingState.idle;
    _sessionError = '';
    notifyListeners();
  }

  /// Full reset, including the quiz list/history — call on logout so the
  /// next account on this device doesn't briefly see the previous user's
  /// quiz list/history/session (M6).
  void clear() {
    resetSession();
    _quizList = [];
    _listState = QuizLoadingState.idle;
    _listError = '';
    _quizHistory = [];
    _historyState = QuizLoadingState.idle;
    _historyError = '';
    notifyListeners();
  }
}
