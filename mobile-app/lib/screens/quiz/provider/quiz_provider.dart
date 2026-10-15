import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import '../../../services/api_client.dart';
import '../../../services/common/storage_service.dart';
import '../../../services/quiz_offline_store.dart';
import '../../../services/quiz_reminder_service.dart';
import '../../../services/quiz_submission_service.dart';
import '../../../services/session_renewal_service.dart';
import '../../../utils/json_parsing.dart';
import '../model/quiz_model.dart';
import '../model/question_timing.dart';
import '../model/quiz_progress_record.dart';
import 'quiz_timing_tracker.dart';

enum QuizLoadingState { idle, loading, loaded, error }

/// State management for the live-quiz-list ("Option B") flow.
///
/// All grading is server-side: this provider never computes correctness or
/// a score itself — it only renders what the server returns from
/// `POST /api/quizzes/attempt` (or the `myAttempt` summary from the list
/// endpoints).
///
/// The quiz works offline once opened: the questions are downloaded in one
/// request and the answers are written to the device on every tap (see
/// [QuizOfflineStore]). They leave the device only after the server confirms
/// the attempt ([QuizSubmissionService]).
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

    // Answers a student could not send earlier go out alongside the list
    // request, so a result shows up as soon as the connection is back.
    final flushing = flushPendingSubmissions();
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
    // A waiting submission was just accepted: reload so its score shows.
    if (await flushing) await fetchQuizList();
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

  /// Who the on-device copy belongs to. Null means nothing is saved to the
  /// device (no quiz opened through [startQuiz], e.g. in unit tests).
  String? _userId;

  /// True once Submit was pressed; the answers are then final and sent as soon
  /// as the server can be reached.
  bool _submitPending = false;
  int? _frozenDuration;
  bool _openedFromDevice = false;

  /// Per-question timing and the countdown deadlines.
  QuizTimingTracker _tracker = QuizTimingTracker();

  /// The app is in the background: a question reached meanwhile is not shown
  /// yet, so its clock waits for the student to come back.
  bool _paused = false;
  DateTime? _endsAt;

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

  /// Whether the whole quiz has a time limit.
  bool get hasOverallTimer =>
      (_timerMode == 'overall' || _timerMode == 'both') &&
      (_overallTimeLimit ?? 0) > 0;

  /// Whether each question has its own time limit. Such a quiz only moves
  /// forward: there is no going back to an earlier question.
  bool get hasPerQuestionTimer =>
      (_timerMode == 'per-question' || _timerMode == 'both') &&
      (_perQuestionTimeLimit ?? 0) > 0;

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

  /// The quiz was opened from the copy on the device because the server could
  /// not be reached.
  bool get openedFromDevice => _openedFromDevice;

  /// When the whole quiz's time runs out (phone clock), or null with no
  /// whole-quiz limit. Counted from when the server first handed out the
  /// questions, so closing the app, reinstalling it or changing the phone's
  /// time never refills it.
  DateTime? get overallDeadline => _tracker.overallDeadline;

  /// When the quiz closes at its end time (phone clock): it is submitted then
  /// whatever time limits it has. Null when the server sent no end time.
  DateTime? get closingDeadline => _tracker.closingDeadline;

  /// The quiz's end time as the server set it, for messages.
  DateTime? get endsAt => _endsAt;

  /// When the current question's own time runs out, or null when questions
  /// have no time limit. Its clock started when it was first shown.
  DateTime? get questionDeadline {
    final question = currentQuestion;
    return question == null ? null : _tracker.questionDeadline(question.id);
  }

  /// How long [questionId] has taken so far, and its countdown state.
  QuestionTiming timingOf(String questionId) => _tracker.timingOf(questionId);

  /// Shown when a submitted quiz, still waiting to be sent, is tapped.
  static const String submittedWaitingMessage =
      "Your answers are submitted and waiting to be sent. They'll go as soon "
      "as there's a connection.";

  /// Whether [quizId] was submitted on this phone and is waiting to be sent.
  bool isWaitingToSend(String quizId) =>
      _pendingSubmissions.any((r) => r.quizId == quizId);

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
  ///
  /// The questions are saved to the device as soon as they arrive. If the
  /// server cannot be reached and a saved copy exists, the quiz opens from it
  /// with the student's earlier answers; with no saved copy the call throws.
  Future<void> startQuiz(String quizId, {String? language}) async {
    _sessionState = QuizLoadingState.loading;
    _sessionError = '';
    _quizId = quizId;
    _userId = null;
    _openedFromDevice = false;
    if (language != null) _sessionLanguage = language;
    notifyListeners();

    // A sign-in about to run out is renewed now, not mid-quiz.
    unawaited(SessionRenewalService.renewIfNeeded());
    final userId = await _currentUserId();
    final saved = await QuizOfflineStore.loadProgress(userId, quizId);
    if (saved != null && saved.isRetryable) {
      // Submit was pressed: the answers are final and only waiting to be
      // sent, so the quiz is not reopened for changes.
      _sessionState = QuizLoadingState.error;
      _sessionError = submittedWaitingMessage;
      throw ApiException(0, _sessionError);
    }
    Map<String, dynamic> data;
    var fromDevice = false;
    int? offsetMs;
    try {
      final sentAt = clock.now();
      data =
          await ApiClient.get(
                '/api/user-quizzes/$quizId/questions',
                // Someone resuming gives up on a dead connection sooner.
                timeout: saved == null ? null : const Duration(seconds: 6),
              )
              as Map<String, dynamic>;
      offsetMs = _clockOffset(data['serverNow'], sentAt, clock.now());
      await QuizOfflineStore.saveSession(userId, quizId, data);
    } catch (e) {
      final cached = QuizSubmissionService.isConnectionTrouble(e)
          ? await QuizOfflineStore.loadSession(userId, quizId)
          : null;
      if (cached == null) {
        _sessionState = QuizLoadingState.error;
        // The server already holds this student's attempt, so a half-finished
        // copy on the device has nothing left to send.
        if (e is ApiException && e.status == 409) {
          await QuizOfflineStore.clear(userId, quizId);
        }
        if (e is ApiException) {
          _sessionError = e.message;
          rethrow;
        }
        _sessionError =
            "You're offline. Connect to the internet to start this quiz.";
        throw ApiException(0, _sessionError);
      }
      data = cached;
      fromDevice = true;
    }
    _userId = userId;
    _openedFromDevice = fromDevice;
    _applySessionData(data, resume: saved, offsetMs: offsetMs);
    final closes = closingDeadline;
    if (closes != null && !_submitPending) {
      unawaited(
        QuizReminderService.schedule(
          quizId: quizId,
          title: _quizTitle,
          closesAt: closes,
        ),
      );
    }
    notifyListeners();
  }

  /// Server time minus phone time, taking the server's clock as read halfway
  /// through the request. Null when the server did not send its time.
  static int? _clockOffset(Object? serverNow, DateTime sent, DateTime got) {
    final server = DateTime.tryParse('${serverNow ?? ''}');
    if (server == null) return null;
    final midpoint = sent.add(got.difference(sent) ~/ 2);
    return server.difference(midpoint).inMilliseconds;
  }

  Future<String> _currentUserId() async {
    final id = await StorageService.getString('userId');
    return id.isEmpty ? 'anon' : id;
  }

  /// Fills the session from [data]. With a saved [resume] record for this quiz
  /// the student's answers, position and start time come back too.
  void _applySessionData(
    Map<String, dynamic> data, {
    QuizProgressRecord? resume,
    int? offsetMs,
  }) {
    _quizTitle = data['title'] as String? ?? '';
    _overallTimeLimit = jsonInt(data['overallTimeLimit']);
    _perQuestionTimeLimit = jsonInt(data['perQuestionTimeLimit']);
    _timerMode = data['timerMode'] as String? ?? 'none';
    _sessionQuestions = (data['questions'] as List<dynamic>? ?? [])
        .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
        .toList();

    _answers.clear();
    for (final q in _sessionQuestions) {
      _answers[q.id] = resume?.answers[q.id];
    }
    _currentQuestionIndex = _sessionQuestions.isEmpty
        ? 0
        : (resume?.currentIndex ?? 0).clamp(0, _sessionQuestions.length - 1);
    final now = clock.now();
    _quizStartTime = resume?.startedAt ?? now;
    _endsAt = DateTime.tryParse('${data['endDate'] ?? ''}');
    _submitPending = resume?.submitPending ?? false;
    _frozenDuration = resume?.totalDuration;
    _tracker = QuizTimingTracker()
      ..load(
        questionIds: [for (final q in _sessionQuestions) q.id],
        localStart: _quizStartTime!,
        saved: resume?.timings ?? const {},
        savedAt: resume?.savedAt,
        serverStartedAt: DateTime.tryParse('${data['startedAt'] ?? ''}'),
        endsAt: _endsAt,
        offsetMs: offsetMs ?? resume?.clockOffsetMs ?? 0,
        overallLimit: hasOverallTimer ? _overallTimeLimit : null,
        perQuestionLimit: hasPerQuestionTimer ? _perQuestionTimeLimit : null,
      );
    final current = currentQuestion;
    if (current != null) _tracker.show(current.id, now);
    _lastAttempt = null;
    _sessionState = QuizLoadingState.loaded;
    _persistProgress();
  }

  /// The student's quiz as it stands, in the form kept on the device.
  QuizProgressRecord _snapshot() => QuizProgressRecord(
    quizId: _quizId!,
    title: _quizTitle,
    questionIds: [for (final q in _sessionQuestions) q.id],
    answers: Map.of(_answers),
    language: _sessionLanguage,
    startedAt: _quizStartTime ?? clock.now(),
    currentIndex: _currentQuestionIndex,
    submitPending: _submitPending,
    totalDuration: _frozenDuration,
    timings: _tracker.timings,
    serverStartedAt: _tracker.serverStartedAt,
    endsAt: _endsAt,
    clockOffsetMs: _tracker.offsetMs,
    savedAt: clock.now(),
  );

  /// Writes the current answers and position to the device. Called after
  /// every change; writes are queued in order, so the last tap always wins.
  void _persistProgress() {
    final userId = _userId;
    if (userId == null || _quizId == null || _sessionQuestions.isEmpty) return;
    unawaited(QuizOfflineStore.saveProgress(userId, _snapshot()));
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
    String timerMode = 'none',
    int? overallTimeLimit,
    int? perQuestionTimeLimit,
    DateTime? endsAt,
  }) {
    _quizId = quizId ?? 'test-quiz';
    _applySessionData({
      'title': 'Test Quiz',
      'questions': questionsJson,
      'timerMode': timerMode,
      'overallTimeLimit': overallTimeLimit,
      'perQuestionTimeLimit': perQuestionTimeLimit,
      'endDate': endsAt?.toIso8601String(),
    });
  }

  /// Picks an option for the current question. Ignored once the question's
  /// or the quiz's time has run out.
  void selectAnswer(int answerIndex) {
    final question = currentQuestion;
    if (question == null) return;
    final now = clock.now();
    if (!_tracker.isOpen(question.id, now)) return;
    _tracker.answered(
      question.id,
      now,
      previous: _answers[question.id],
      choice: answerIndex,
    );
    _answers[question.id] = answerIndex;
    _persistProgress();
    notifyListeners();
  }

  void nextQuestion() {
    if (hasNextQuestion) _moveTo(_currentQuestionIndex + 1);
  }

  void previousQuestion() {
    if (hasPreviousQuestion) _moveTo(_currentQuestionIndex - 1);
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < _sessionQuestions.length) _moveTo(index);
  }

  void _moveTo(int index) {
    final now = clock.now();
    final from = currentQuestion;
    if (from != null) _tracker.hide(from.id, now);
    _currentQuestionIndex = index;
    if (!_paused) _tracker.show(_sessionQuestions[index].id, now);
    _persistProgress();
    notifyListeners();
  }

  /// The current question's time ran out: it is marked timed out (keeping an
  /// answer picked in time) and the next question is shown, its clock starting
  /// now. Returns false on the last question, where the quiz should submit.
  bool timeOutCurrentQuestion() {
    final question = currentQuestion;
    if (question == null) return false;
    _tracker.expire(question.id, clock.now());
    if (hasNextQuestion) {
      _moveTo(_currentQuestionIndex + 1);
      return true;
    }
    _persistProgress();
    notifyListeners();
    return false;
  }

  /// The app went to the background or the quiz screen closed: the question
  /// on screen stops counting time on screen (its countdown keeps running).
  /// Does not notify, so it is safe to call while the screen is torn down.
  void pauseVisit() {
    _paused = true;
    final question = currentQuestion;
    if (question == null) return;
    _tracker.hide(question.id, clock.now());
    _persistProgress();
  }

  /// The app came back to the front with the quiz on screen. A question the
  /// quiz moved to while in the background is shown now, starting its clock.
  void resumeVisit() {
    _paused = false;
    final question = currentQuestion;
    if (question == null) return;
    final now = clock.now();
    if (_tracker.timingOf(question.id).firstShownAt == null) {
      _tracker.show(question.id, now);
    } else {
      _tracker.resume(question.id, now);
    }
    _persistProgress();
    notifyListeners();
  }

  // ---- Submission ----
  QuizAttemptResult? _lastAttempt;
  QuizAttemptResult? get lastAttempt => _lastAttempt;

  /// `POST /api/quizzes/attempt`. On success (`201`) or a `409`
  /// already-attempted response (whose body still carries the existing
  /// `attempt`), this sets [lastAttempt] and returns it so the caller can
  /// navigate to a results screen. On any other error the [ApiException]
  /// propagates for the caller to display (e.g. 403 quiz-not-live).
  ///
  /// The final answers are written to the device before anything is sent and
  /// removed only once the server confirms, so a failed send (no connection,
  /// server busy) loses nothing: call this again, or let
  /// [flushPendingSubmissions] do it later.
  Future<QuizAttemptResult> submitQuiz() async {
    if (_quizId == null || _sessionQuestions.isEmpty) {
      throw StateError('No active quiz session to submit');
    }

    final now = clock.now();
    final current = currentQuestion;
    if (current != null) _tracker.hide(current.id, now);
    _frozenDuration ??= _tracker.secondsSinceStart(now);
    _submitPending = true;
    final record = _snapshot();
    final userId = _userId;
    if (userId != null) await QuizOfflineStore.saveProgress(userId, record);

    final attempt = await QuizSubmissionService.send(userId, record);
    // The server has the attempt and the device copy is gone; nothing may
    // write it back (e.g. the screen closing right after).
    _userId = null;
    _lastAttempt = attempt;
    notifyListeners();
    return attempt;
  }

  // ---- Submissions waiting on the device ----
  List<QuizProgressRecord> _pendingSubmissions = [];
  List<QuizProgressRecord> _refusedSubmissions = [];
  List<QuizProgressRecord> _inProgressQuizzes = [];
  bool _flushing = false;

  /// Quizzes whose answers are saved on the device but not yet accepted.
  List<QuizProgressRecord> get pendingSubmissions => _pendingSubmissions;

  /// Quizzes started on this phone and not yet submitted, still open: shown
  /// as "Continue" when the quiz list cannot be loaded (offline).
  List<QuizProgressRecord> get inProgressQuizzes => _inProgressQuizzes;

  /// Quizzes whose answers the server refused for good (too late, switched
  /// off, changed, removed). Shown to the student until [dismissRefused].
  List<QuizProgressRecord> get refusedSubmissions => _refusedSubmissions;

  /// The student has seen why [quizId]'s answers were refused: the server's
  /// answer is final, so the copy on the device goes.
  Future<void> dismissRefused(String quizId) async {
    // The quiz screen may still be closing; it must not write the copy back.
    if (quizId == _quizId) _userId = null;
    unawaited(QuizReminderService.cancel(quizId));
    final userId = await _currentUserId();
    await QuizOfflineStore.clear(userId, quizId);
    _refusedSubmissions = await QuizOfflineStore.refused(userId);
    notifyListeners();
  }

  bool get isFlushing => _flushing;

  /// How many quizzes have answers on this phone that the server does not
  /// have yet (waiting to send, or started and partly answered).
  Future<int> unsentQuizCount() async {
    final userId = await _currentUserId();
    return (await QuizOfflineStore.unsent(userId)).length;
  }

  /// Deletes every saved quiz of the signed-in student from this phone, on
  /// logout. Their reminders go with logout's own clean-up.
  Future<void> deleteSavedQuizzes() async {
    _userId = null; // a quiz screen still closing must not write back
    final userId = await _currentUserId();
    await QuizOfflineStore.clearAll(userId);
  }

  /// Sends every submission waiting on the device and refreshes
  /// [pendingSubmissions]. Returns whether any was accepted. Never throws.
  Future<bool> flushPendingSubmissions() async {
    if (_flushing) return false;
    _flushing = true;
    notifyListeners();
    var sent = false;
    try {
      final userId = await _currentUserId();
      // The quiz open on screen submits by itself; leave it alone.
      final open = _userId != null ? _quizId : null;
      await QuizSubmissionService.discardAbandoned(
        userId,
        clock.now(),
        except: open,
      );
      await QuizSubmissionService.sealClosedQuizzes(
        userId,
        clock.now(),
        except: open,
      );
      sent = await QuizSubmissionService.flushPending(userId, except: open);
      _pendingSubmissions = await QuizOfflineStore.pending(userId);
      _refusedSubmissions = await QuizOfflineStore.refused(userId);
      _inProgressQuizzes = await QuizOfflineStore.inProgress(
        userId,
        clock.now(),
      );
    } catch (e) {
      debugPrint('Could not send waiting quiz answers: $e');
    } finally {
      _flushing = false;
      notifyListeners();
    }
    return sent;
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
    _userId = null;
    _submitPending = false;
    _frozenDuration = null;
    _openedFromDevice = false;
    _paused = false;
    _endsAt = null;
    _tracker = QuizTimingTracker();
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
    // Only the screen's view is cleared: answers saved on the device stay for
    // the same student's next sign-in and are never shown to another account.
    _pendingSubmissions = [];
    _refusedSubmissions = [];
    _inProgressQuizzes = [];
    notifyListeners();
  }
}
