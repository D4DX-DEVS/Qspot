import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../screens/quiz/model/quiz_model.dart';
import '../screens/quiz/model/quiz_progress_record.dart';
import 'api_client.dart';
import 'quiz_offline_store.dart';
import 'quiz_reminder_service.dart';

/// Sends a student's answers to the server and decides what happens to the
/// copy kept on the device.
///
/// The rule that protects the student: the on-device copy is deleted only when
/// the server has confirmed the attempt, which is a `201`, or a `409` whose body
/// carries the already-saved attempt (the server saved an earlier try whose
/// reply never arrived). Every other outcome (no connection, timeout, server
/// error, even a refusal) leaves the answers on the device. Because the server
/// grades once per student and quiz, sending again is always safe.
class QuizSubmissionService {
  QuizSubmissionService._();

  /// Pauses before the automatic re-sends of an overloaded-server reply.
  @visibleForTesting
  static List<Duration> retryDelays = const [
    Duration(milliseconds: 800),
    Duration(milliseconds: 2400),
  ];

  static final Random _random = Random();

  /// Replies that mean "busy right now": worth a quick automatic re-send, with
  /// a random extra pause so a whole class does not come back in the same
  /// instant.
  static bool _isOverloaded(int status) =>
      status == 429 || status == 502 || status == 503 || status == 504;

  /// A refusal the server will repeat however often it is asked (quiz closed,
  /// bad request, not found). Retrying is pointless, but the answers stay.
  static bool isDefiniteRejection(ApiException e) =>
      e.status >= 400 &&
      e.status < 500 &&
      !e.isAuthFailure &&
      !const {408, 409, 429}.contains(e.status);

  /// The server refused the answers because they arrived after the quiz
  /// closed (past its grace period).
  static bool isTooLate(ApiException e) =>
      e.status == 403 &&
      e.body is Map &&
      (e.body as Map)['code'] == QuizProgressRecord.tooLateCode;

  /// Whether [error] says nothing about the quiz itself (no connection, a
  /// timeout, a server fault), so a saved copy can stand in for the server.
  static bool isConnectionTrouble(Object error) =>
      error is! ApiException ||
      error.status >= 500 ||
      error.status == 408 ||
      error.status == 429;

  /// Sends [record] and returns the graded attempt. On success the device copy
  /// is removed. Throws on every failure, leaving the copy in place (marked as
  /// refused when the server's answer is final).
  static Future<QuizAttemptResult> send(
    String? userId,
    QuizProgressRecord record,
  ) async {
    try {
      final data = await _post(
        record.toSubmissionBody(record.totalDuration ?? 0),
      );
      final attempt = QuizAttemptResult.fromJson(
        data['attempt'] as Map<String, dynamic>,
      );
      await _forget(userId, record.quizId);
      return attempt;
    } on ApiException catch (e) {
      final saved = e.status == 409 && e.body is Map
          ? (e.body as Map)['attempt']
          : null;
      if (saved is Map<String, dynamic>) {
        // Already attempted: the server holds the answers, show that result.
        await _forget(userId, record.quizId);
        return QuizAttemptResult.fromJson(saved);
      }
      if (isDefiniteRejection(e)) {
        // Final: no point reminding the student to submit any more.
        unawaited(QuizReminderService.cancel(record.quizId));
      }
      if (userId != null && isDefiniteRejection(e)) {
        final code = e.body is Map ? (e.body as Map)['code'] : null;
        await QuizOfflineStore.saveProgress(
          userId,
          record.copyWith(
            rejectedStatus: e.status,
            rejectedCode: code is String ? code : null,
          ),
        );
      }
      rethrow;
    }
  }

  /// Deletes copies of quizzes that were opened but never answered once the
  /// quiz is over: they have nothing to send.
  static Future<void> discardAbandoned(
    String userId,
    DateTime now, {
    String? except,
  }) async {
    final abandoned = await QuizOfflineStore.abandoned(userId, now);
    for (final record in abandoned.where((r) => r.quizId != except)) {
      await _forget(userId, record.quizId);
    }
  }

  /// A quiz whose end time passed while the app was not open on it was never
  /// submitted. Its answers as last saved become a waiting submission, sent
  /// by [flushPending]: accepted within the grace period, otherwise refused
  /// as too late, which the student is then told. A quiz opened but not
  /// answered at all is left alone rather than sent as an empty attempt.
  static Future<void> sealClosedQuizzes(
    String userId,
    DateTime now, {
    String? except,
  }) async {
    final closed = await QuizOfflineStore.closedUnsubmitted(userId, now);
    for (final record in closed.where(
      (r) => r.answeredCount > 0 && r.quizId != except,
    )) {
      await QuizOfflineStore.saveProgress(userId, record.sealedAfterClose());
    }
  }

  /// Tries every submission waiting on the device. Returns whether any was
  /// accepted. A failure just leaves that one for the next try.
  static Future<bool> flushPending(String userId, {String? except}) async {
    var sent = false;
    final waiting = await QuizOfflineStore.pending(userId);
    for (final record in waiting.where((r) => r.quizId != except)) {
      try {
        await send(userId, record);
        sent = true;
      } catch (e) {
        debugPrint('Quiz submission for ${record.quizId} still waiting: $e');
      }
    }
    return sent;
  }

  static Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    for (var tried = 0; ; tried++) {
      try {
        return await ApiClient.post('/api/quizzes/attempt', body: body)
            as Map<String, dynamic>;
      } on ApiException catch (e) {
        if (!_isOverloaded(e.status) || tried >= retryDelays.length) rethrow;
        final base = retryDelays[tried];
        await Future<void>.delayed(base + base * (_random.nextDouble() * 0.5));
      }
    }
  }

  static Future<void> _forget(String? userId, String quizId) async {
    unawaited(QuizReminderService.cancel(quizId));
    if (userId != null) await QuizOfflineStore.clear(userId, quizId);
  }
}
