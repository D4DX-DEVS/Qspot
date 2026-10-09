/// Quiz models for the "Option B" live-quiz-list API contract.
///
/// All grading and correctness happens server-side. The client never
/// computes or stores a correct answer for an in-progress quiz — only
/// [QuestionResult] (returned after a genuine submission) carries a
/// `correctAnswer` field, and it comes straight from the server.
library;

import '../../../utils/json_parsing.dart';

/// Summary of the current user's attempt on a quiz, as embedded in
/// [QuizListItem.myAttempt].
class MyAttemptSummary {
  final String attemptId;
  final int score;
  final int totalQuestions;
  final num percentage;
  final DateTime? createdAt;

  MyAttemptSummary({
    required this.attemptId,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.createdAt,
  });

  factory MyAttemptSummary.fromJson(Map<String, dynamic> json) {
    return MyAttemptSummary(
      attemptId: json['attemptId']?.toString() ?? '',
      score: jsonInt(json['score']) ?? 0,
      totalQuestions: jsonInt(json['totalQuestions']) ?? 0,
      percentage: jsonDouble(json['percentage']) ?? 0,
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

/// One entry from `GET /api/user-quizzes` (or a single `GET
/// /api/user-quizzes/:id`).
class QuizListItem {
  final String id;
  final String title;
  final String assessmentType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int numberOfQuestions;
  final bool questionsRandomization;
  final int? overallTimeLimit;
  final int? perQuestionTimeLimit;
  final String timerMode;
  final int? optionsCount;
  final String status; // 'upcoming' | 'live' | 'ended'
  final int questionCount;
  final MyAttemptSummary? myAttempt;

  QuizListItem({
    required this.id,
    required this.title,
    required this.assessmentType,
    required this.startDate,
    required this.endDate,
    required this.numberOfQuestions,
    required this.questionsRandomization,
    required this.overallTimeLimit,
    required this.perQuestionTimeLimit,
    required this.timerMode,
    required this.optionsCount,
    required this.status,
    required this.questionCount,
    required this.myAttempt,
  });

  factory QuizListItem.fromJson(Map<String, dynamic> json) {
    return QuizListItem(
      id: json['_id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      assessmentType: json['assessmentType'] as String? ?? 'quiz',
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      numberOfQuestions: jsonInt(json['numberOfQuestions']) ?? 0,
      questionsRandomization: json['questionsRandomization'] as bool? ?? false,
      overallTimeLimit: jsonInt(json['overallTimeLimit']),
      perQuestionTimeLimit: jsonInt(json['perQuestionTimeLimit']),
      timerMode: json['timerMode'] as String? ?? 'none',
      optionsCount: jsonInt(json['optionsCount']),
      status: json['status'] as String? ?? 'ended',
      questionCount: jsonInt(json['questionCount']) ?? 0,
      myAttempt: json['myAttempt'] is Map<String, dynamic>
          ? MyAttemptSummary.fromJson(json['myAttempt'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isLive => status == 'live';
  bool get isUpcoming => status == 'upcoming';
  bool get isEnded => status == 'ended';
  bool get hasAttempted => myAttempt != null;
}

/// One question as delivered by `GET /api/user-quizzes/:id/questions`.
///
/// Deliberately has NO correct-answer field — the server never sends one
/// before grading.
class QuizQuestion {
  final String id;
  final String type;
  final String questionEn;
  final String questionMl;
  final List<String> optionsEn;
  final List<String> optionsMl;
  final String difficulty;

  QuizQuestion({
    required this.id,
    required this.type,
    required this.questionEn,
    required this.questionMl,
    required this.optionsEn,
    required this.optionsMl,
    required this.difficulty,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['_id']?.toString() ?? '',
      type: json['type'] as String? ?? 'multiple_choice',
      questionEn: json['question_en'] as String? ?? '',
      questionMl: json['question_ml'] as String? ?? '',
      optionsEn: _parseOptions(json['options_en']),
      optionsMl: _parseOptions(json['options_ml']),
      difficulty: json['difficulty'] as String? ?? 'medium',
    );
  }

  /// Question text for the given locale ('en' or 'ml'), falling back to
  /// English if the Malayalam text is missing.
  String getQuestion(String locale) {
    if (locale == 'ml' && questionMl.isNotEmpty) return questionMl;
    return questionEn;
  }

  /// Options for the given locale, falling back to English options if the
  /// Malayalam list is missing or shorter than the English one (guards
  /// against a RangeError if the ML content is incomplete for a question).
  List<String> getOptions(String locale) {
    if (locale == 'ml' &&
        optionsMl.length >= optionsEn.length &&
        optionsMl.isNotEmpty) {
      return optionsMl;
    }
    return optionsEn;
  }
}

/// A single question's outcome from either `POST /api/quizzes/attempt`'s
/// `attempt.results` or a full attempt review — always server-graded.
class QuestionResult {
  final String questionId;
  final String type;
  final String questionEn;
  final String questionMl;
  final List<String> optionsEn;
  final List<String> optionsMl;
  final int? attemptedAnswer;
  final int correctAnswer;
  final bool isCorrect;

  QuestionResult({
    required this.questionId,
    required this.type,
    required this.questionEn,
    required this.questionMl,
    required this.optionsEn,
    required this.optionsMl,
    required this.attemptedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      questionId: json['questionId']?.toString() ?? '',
      type: json['type'] as String? ?? 'multiple_choice',
      questionEn: json['question_en'] as String? ?? '',
      questionMl: json['question_ml'] as String? ?? '',
      optionsEn: _parseOptions(json['options_en']),
      optionsMl: _parseOptions(json['options_ml']),
      attemptedAnswer: jsonInt(json['attemptedAnswer']),
      correctAnswer: jsonInt(json['correctAnswer']) ?? -1,
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }

  String getQuestion(String locale) {
    if (locale == 'ml' && questionMl.isNotEmpty) return questionMl;
    return questionEn;
  }

  List<String> getOptions(String locale) {
    if (locale == 'ml' &&
        optionsMl.length >= optionsEn.length &&
        optionsMl.isNotEmpty) {
      return optionsMl;
    }
    return optionsEn;
  }
}

/// The `attempt` object returned by a successful (or 409-already-attempted)
/// `POST /api/quizzes/attempt`, and by history lookups that include results.
class QuizAttemptResult {
  final String attemptId;
  final String quizId;
  final String title;
  final String language;
  final int score;
  final int totalQuestions;
  final num percentage;
  final int totalDuration;
  final DateTime? createdAt;
  final List<QuestionResult> results;

  QuizAttemptResult({
    required this.attemptId,
    required this.quizId,
    required this.title,
    required this.language,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.totalDuration,
    required this.createdAt,
    required this.results,
  });

  factory QuizAttemptResult.fromJson(Map<String, dynamic> json) {
    return QuizAttemptResult(
      attemptId: json['attemptId']?.toString() ?? '',
      quizId: json['quizId']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      score: jsonInt(json['score']) ?? 0,
      totalQuestions: jsonInt(json['totalQuestions']) ?? 0,
      percentage: jsonDouble(json['percentage']) ?? 0,
      totalDuration: jsonInt(json['totalDuration']) ?? 0,
      createdAt: _parseDate(json['createdAt']),
      results:
          (json['results'] as List<dynamic>?)
              ?.map((e) => QuestionResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// One row of `GET /api/user/quiz-attempts` (quiz history — no per-question
/// results, just the summary).
class QuizHistoryItem {
  final String attemptId;
  final String quizId;
  final String title;
  final String language;
  final int score;
  final int totalQuestions;
  final num percentage;
  final int totalDuration;
  final DateTime? createdAt;

  QuizHistoryItem({
    required this.attemptId,
    required this.quizId,
    required this.title,
    required this.language,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.totalDuration,
    required this.createdAt,
  });

  factory QuizHistoryItem.fromJson(Map<String, dynamic> json) {
    return QuizHistoryItem(
      attemptId: json['attemptId']?.toString() ?? '',
      quizId: json['quizId']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      score: jsonInt(json['score']) ?? 0,
      totalQuestions: jsonInt(json['totalQuestions']) ?? 0,
      percentage: jsonDouble(json['percentage']) ?? 0,
      totalDuration: jsonInt(json['totalDuration']) ?? 0,
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

List<String> _parseOptions(dynamic options) {
  if (options is List) {
    return options.map((e) => e.toString()).toList();
  }
  return const [];
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    // Server sends UTC; show dates and times in the phone's time zone.
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}
