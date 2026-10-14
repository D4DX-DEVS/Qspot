import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/quiz/model/quiz_progress_record.dart';

/// On-device copy of a quiz in progress, kept per student and per quiz.
///
/// Two entries are written for each quiz:
///  - the **session**: the questions exactly as the server sent them, saved once
///    when the quiz is opened so it can be taken (and re-opened) without a
///    connection;
///  - the **progress**: a small [QuizProgressRecord] (answers, position, start
///    time, whether Submit was pressed), rewritten on every tap.
///
/// Nothing here ever deletes an entry except [clear], which the app calls only
/// after the server has confirmed the attempt. Every write goes through one
/// queue, so a late progress write can never land after a [clear] and bring a
/// finished quiz back, and no call here throws: storage trouble must not break
/// a quiz that is otherwise working.
class QuizOfflineStore {
  QuizOfflineStore._();

  static const String _sessionPrefix = 'quiz_offline_session_';
  static const String _progressPrefix = 'quiz_offline_progress_';

  // The last queued job, or null when the queue is empty. Dropped once idle so
  // a new run of jobs never chains onto an old, finished future (which, in
  // tests, can belong to a fake-time zone that no longer runs).
  static Future<void>? _tail;
  static int _pending = 0;

  static Future<T> _queued<T>(Future<T> Function() job, T onError) {
    final previous = _tail ?? Future<void>.value();
    _pending++;
    final result = previous.then((_) => job()).catchError((Object e) {
      debugPrint('QuizOfflineStore: $e');
      return onError;
    });
    _tail = result.then<void>((_) {}).whenComplete(() {
      if (--_pending == 0) _tail = null;
    });
    return result;
  }

  /// Completes once every write started so far has finished.
  static Future<void> idle() => _tail ?? Future<void>.value();

  static String _id(String userId, String quizId) => '${userId}_$quizId';

  static Future<bool> saveSession(
    String userId,
    String quizId,
    Map<String, dynamic> session,
  ) => _queued(() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(
      '$_sessionPrefix${_id(userId, quizId)}',
      jsonEncode(session),
    );
  }, false);

  static Future<Map<String, dynamic>?> loadSession(
    String userId,
    String quizId,
  ) => _queued<Map<String, dynamic>?>(() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_sessionPrefix${_id(userId, quizId)}');
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }, null);

  static Future<bool> saveProgress(String userId, QuizProgressRecord record) =>
      _queued(() async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.setString(
          '$_progressPrefix${_id(userId, record.quizId)}',
          jsonEncode(record.toJson()),
        );
      }, false);

  static Future<QuizProgressRecord?> loadProgress(
    String userId,
    String quizId,
  ) => _queued<QuizProgressRecord?>(() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_progressPrefix${_id(userId, quizId)}');
    return raw == null ? null : QuizProgressRecord.tryFromJson(jsonDecode(raw));
  }, null);

  /// Submissions waiting to be sent: Submit was pressed and the server has not
  /// refused them for good. Oldest first.
  static Future<List<QuizProgressRecord>> pending(String userId) =>
      _records(userId, (r) => r.isRetryable);

  /// Answers the server refused for good (too late, quiz switched off,
  /// changed or removed), waiting for the student to see why.
  static Future<List<QuizProgressRecord>> refused(String userId) =>
      _records(userId, (r) => r.isRefused);

  /// Quizzes started on this phone, not submitted, and still open at [now]:
  /// the student can carry on with them, even offline.
  static Future<List<QuizProgressRecord>> inProgress(
    String userId,
    DateTime now,
  ) => _records(
    userId,
    (r) =>
        !r.submitPending &&
        r.rejectedStatus == null &&
        !r.closedUnsubmitted(now),
  );

  /// Copies with nothing to send or continue at [now]; see
  /// [QuizProgressRecord.abandoned].
  static Future<List<QuizProgressRecord>> abandoned(
    String userId,
    DateTime now,
  ) => _records(userId, (r) => r.abandoned(now));

  /// Quizzes started but not submitted whose end time has passed at [now].
  static Future<List<QuizProgressRecord>> closedUnsubmitted(
    String userId,
    DateTime now,
  ) => _records(userId, (r) => r.closedUnsubmitted(now));

  static Future<List<QuizProgressRecord>> _records(
    String userId,
    bool Function(QuizProgressRecord) keep,
  ) => _queued<List<QuizProgressRecord>>(() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '$_progressPrefix${userId}_';
    final found = <QuizProgressRecord>[];
    for (final key in prefs.getKeys().where((k) => k.startsWith(prefix))) {
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        final record = QuizProgressRecord.tryFromJson(jsonDecode(raw));
        if (record != null && keep(record)) found.add(record);
      } catch (_) {
        // A damaged entry is skipped, never deleted.
      }
    }
    found.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return found;
  }, const []);

  /// Answers not yet with the server: submitted but waiting, or a quiz in
  /// progress with at least one answer.
  static Future<List<QuizProgressRecord>> unsent(String userId) => _records(
    userId,
    (r) => !r.isRefused && (r.submitPending || r.answeredCount > 0),
  );

  /// Removes every quiz copy of [userId] from the phone. Used when the student
  /// logs out after being warned about unsent answers.
  static Future<void> clearAll(String userId) => _queued<void>(() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
      (k) =>
          k.startsWith('$_sessionPrefix${userId}_') ||
          k.startsWith('$_progressPrefix${userId}_'),
    );
    for (final key in keys.toList()) {
      await prefs.remove(key);
    }
  }, null);

  /// Removes the quiz from the device. Call only once the server's answer is
  /// final: the attempt was confirmed, or it was refused and the student has
  /// seen why.
  static Future<void> clear(String userId, String quizId) => _queued(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_sessionPrefix${_id(userId, quizId)}');
    await prefs.remove('$_progressPrefix${_id(userId, quizId)}');
  }, null);
}
