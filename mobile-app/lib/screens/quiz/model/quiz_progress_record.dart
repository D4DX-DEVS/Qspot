/// A student's quiz as kept on the device while they take it: which questions
/// they were given, what they have answered, where they are, when they began,
/// and whether they have pressed Submit yet.
///
/// Everything needed to send the answers later lives here, so a submission
/// survives the app being closed or the network being gone. The record is only
/// ever deleted once the server has confirmed the attempt.
library;

import 'dart:math';

import 'question_timing.dart';

class QuizProgressRecord {
  const QuizProgressRecord({
    required this.quizId,
    required this.title,
    required this.questionIds,
    required this.answers,
    required this.language,
    required this.startedAt,
    this.currentIndex = 0,
    this.submitPending = false,
    this.totalDuration,
    this.rejectedStatus,
    this.rejectedCode,
    this.timings = const {},
    this.serverStartedAt,
    this.endsAt,
    this.clockOffsetMs = 0,
    this.savedAt,
  });

  final String quizId;
  final String title;

  /// The questions in the order they were served.
  final List<String> questionIds;

  /// questionId -> chosen option index, or null while unanswered.
  final Map<String, int?> answers;

  /// 'en' or 'ml', as chosen on the language dialog.
  final String language;
  final DateTime startedAt;
  final int currentIndex;

  /// True once Submit was pressed: the answers are final and waiting to be
  /// accepted by the server.
  final bool submitPending;

  /// Seconds taken, frozen at the moment Submit was pressed.
  final int? totalDuration;

  /// HTTP status of a definite refusal by the server (e.g. 403 quiz closed).
  /// The answers are kept, but the app stops retrying on its own.
  final int? rejectedStatus;

  /// The server's reason code for that refusal, e.g. [tooLateCode].
  final String? rejectedCode;

  /// The server's reasons for refusing answers (see Qspot-API
  /// routes/quizzes.js). The answers reached it after the quiz closed:
  static const String tooLateCode = 'QUIZ_CLOSED';

  /// The teacher switched the quiz off.
  static const String switchedOffCode = 'QUIZ_DISABLED';

  /// The quiz was deleted.
  static const String removedCode = 'QUIZ_NOT_FOUND';

  /// The quiz's questions were changed after the student started.
  static const Set<String> questionsChangedCodes = {
    'QUESTIONS_CHANGED',
    'NO_SESSION',
  };

  bool get arrivedTooLate => rejectedCode == tooLateCode;

  /// The server refused these answers for good.
  bool get isRefused => rejectedStatus != null;

  /// Refused because the questions changed: the quiz can be taken again.
  bool get canRetake => questionsChangedCodes.contains(rejectedCode);

  /// questionId -> how long that question took (and its countdown state).
  final Map<String, QuestionTiming> timings;

  /// When the server first handed out the questions; the quiz clock runs from
  /// here, so it survives reinstalling the app or changing the phone's time.
  final DateTime? serverStartedAt;

  /// When the quiz closes (server clock).
  final DateTime? endsAt;

  /// Server time minus phone time, measured when the quiz was last opened
  /// online.
  final int clockOffsetMs;

  /// Last time this record was written: the app was certainly running then.
  final DateTime? savedAt;

  /// Waiting to be sent, and not refused for good.
  bool get isRetryable => submitPending && rejectedStatus == null;

  int get answeredCount => answers.values.where((v) => v != null).length;

  /// Started, not submitted, and the quiz closed at [now] (phone clock): the
  /// app was not open on the quiz when it ended, so nothing was sent.
  bool closedUnsubmitted(DateTime now) =>
      !submitPending &&
      rejectedStatus == null &&
      endsAt != null &&
      now.add(Duration(milliseconds: clockOffsetMs)).isAfter(endsAt!);

  /// How long a copy saved without an end time is kept when unanswered.
  static const Duration unansweredKeep = Duration(days: 30);

  /// Opened but nothing answered, and the quiz is over (or, with no end time
  /// saved, the copy is older than [unansweredKeep]): nothing to send or
  /// continue, so the copy can go.
  bool abandoned(DateTime now) =>
      !submitPending &&
      rejectedStatus == null &&
      answeredCount == 0 &&
      (endsAt == null
          ? now.difference(startedAt) > unansweredKeep
          : closedUnsubmitted(now));

  /// The answers as last saved become final, as if Submit had been pressed
  /// the last moment the app was known to be running.
  QuizProgressRecord sealedAfterClose() {
    final lastSeen = savedAt ?? startedAt;
    final start =
        serverStartedAt?.subtract(Duration(milliseconds: clockOffsetMs)) ??
        startedAt;
    return QuizProgressRecord(
      quizId: quizId,
      title: title,
      questionIds: questionIds,
      answers: answers,
      language: language,
      startedAt: startedAt,
      currentIndex: currentIndex,
      submitPending: true,
      totalDuration: max(0, lastSeen.difference(start).inSeconds),
      timings: {
        for (final e in timings.entries) e.key: e.value.hidden(lastSeen),
      },
      serverStartedAt: serverStartedAt,
      endsAt: endsAt,
      clockOffsetMs: clockOffsetMs,
      savedAt: savedAt,
    );
  }

  /// The body of `POST /api/quizzes/attempt`.
  Map<String, dynamic> toSubmissionBody(int duration) => {
    'quizId': quizId,
    // The server only recognises the literal 'Malayalam'.
    'language': language == 'ml' ? 'Malayalam' : 'English',
    'answers': [
      for (final id in questionIds)
        {
          'questionId': id,
          'attemptedAnswer': answers[id],
          ...(timings[id] ?? const QuestionTiming()).toSubmission(),
        },
    ],
    'totalDuration': duration,
  };

  QuizProgressRecord copyWith({
    Map<String, int?>? answers,
    int? currentIndex,
    bool? submitPending,
    int? totalDuration,
    int? rejectedStatus,
    String? rejectedCode,
    bool clearRejected = false,
  }) {
    return QuizProgressRecord(
      quizId: quizId,
      title: title,
      questionIds: questionIds,
      answers: answers ?? this.answers,
      language: language,
      startedAt: startedAt,
      currentIndex: currentIndex ?? this.currentIndex,
      submitPending: submitPending ?? this.submitPending,
      totalDuration: totalDuration ?? this.totalDuration,
      rejectedStatus: clearRejected
          ? null
          : (rejectedStatus ?? this.rejectedStatus),
      rejectedCode: clearRejected ? null : (rejectedCode ?? this.rejectedCode),
      timings: timings,
      serverStartedAt: serverStartedAt,
      endsAt: endsAt,
      clockOffsetMs: clockOffsetMs,
      savedAt: savedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'quizId': quizId,
    'title': title,
    'questionIds': questionIds,
    'answers': answers,
    'language': language,
    'startedAt': startedAt.toIso8601String(),
    'currentIndex': currentIndex,
    'submitPending': submitPending,
    'totalDuration': totalDuration,
    'rejectedStatus': rejectedStatus,
    'rejectedCode': rejectedCode,
    'timings': {for (final e in timings.entries) e.key: e.value.toJson()},
    'serverStartedAt': serverStartedAt?.toIso8601String(),
    'endsAt': endsAt?.toIso8601String(),
    'clockOffsetMs': clockOffsetMs,
    'savedAt': savedAt?.toIso8601String(),
  };

  /// Null when [json] is not a usable record (damaged or from another
  /// version), so a bad entry is ignored instead of crashing the quiz.
  static QuizProgressRecord? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final quizId = json['quizId'];
    final ids = json['questionIds'];
    final started = DateTime.tryParse('${json['startedAt']}');
    if (quizId is! String || ids is! List || started == null) return null;
    final rawAnswers = json['answers'];
    final rawTimings = json['timings'];
    DateTime? date(String key) => DateTime.tryParse('${json[key] ?? ''}');
    return QuizProgressRecord(
      quizId: quizId,
      title: json['title'] is String ? json['title'] as String : '',
      questionIds: [for (final id in ids) '$id'],
      answers: {
        if (rawAnswers is Map)
          for (final e in rawAnswers.entries)
            '${e.key}': e.value is int ? e.value as int : null,
      },
      language: json['language'] == 'ml' ? 'ml' : 'en',
      startedAt: started,
      currentIndex: json['currentIndex'] is int
          ? json['currentIndex'] as int
          : 0,
      submitPending: json['submitPending'] == true,
      totalDuration: json['totalDuration'] is int
          ? json['totalDuration'] as int
          : null,
      rejectedStatus: json['rejectedStatus'] is int
          ? json['rejectedStatus'] as int
          : null,
      rejectedCode: json['rejectedCode'] is String
          ? json['rejectedCode'] as String
          : null,
      timings: {
        if (rawTimings is Map)
          for (final e in rawTimings.entries)
            '${e.key}': QuestionTiming.fromJson(e.value),
      },
      serverStartedAt: date('serverStartedAt'),
      endsAt: date('endsAt'),
      clockOffsetMs: json['clockOffsetMs'] is int
          ? json['clockOffsetMs'] as int
          : 0,
      savedAt: date('savedAt'),
    );
  }
}
