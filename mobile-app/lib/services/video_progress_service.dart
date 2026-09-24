import 'package:flutter/foundation.dart';

import '../services/api_client.dart';

/// Server-side watch state for one video.
///
/// `status` is `not-started`, `in-progress` or `completed`. The server decides
/// completion from the seconds actually watched, so seeking to the end does not
/// mark a video complete.
class VideoProgressStatus {
  final String videoId;
  final int positionSeconds;
  final int maxPositionSeconds;
  final int watchedSeconds;
  final int durationSeconds;
  final bool completed;
  final DateTime? completedAt;
  final DateTime? lastViewedAt;
  final String status;
  final int questionCount;
  final bool quizAttempted;

  const VideoProgressStatus({
    required this.videoId,
    this.positionSeconds = 0,
    this.maxPositionSeconds = 0,
    this.watchedSeconds = 0,
    this.durationSeconds = 0,
    this.completed = false,
    this.completedAt,
    this.lastViewedAt,
    this.status = 'not-started',
    this.questionCount = 0,
    this.quizAttempted = false,
  });

  bool get hasQuestions => questionCount > 0;

  /// 0.0 – 1.0, resume position for the "continue watching" bar. Driven by
  /// `positionSeconds` (where playback left off), not `watchedSeconds`.
  double get percent {
    if (completed) return 1;
    if (durationSeconds <= 0) return 0;
    return (positionSeconds / durationSeconds).clamp(0.0, 1.0);
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  factory VideoProgressStatus.fromJson(Map<String, dynamic> json) {
    return VideoProgressStatus(
      videoId: (json['videoId'] ?? '').toString(),
      positionSeconds: (json['positionSeconds'] as num?)?.toInt() ?? 0,
      maxPositionSeconds: (json['maxPositionSeconds'] as num?)?.toInt() ?? 0,
      watchedSeconds: (json['watchedSeconds'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      completed: json['completed'] == true,
      completedAt: _date(json['completedAt']),
      lastViewedAt: _date(json['lastViewedAt']),
      status: (json['status'] ?? 'not-started').toString(),
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      quizAttempted: json['quizAttempted'] == true,
    );
  }
}

/// One question attached to a video. The server never sends the correct
/// answer to the client.
class VideoQuestionItem {
  final String id;
  final String videoId;
  final String type;
  final String questionEn;
  final String questionMl;
  final List<String> optionsEn;
  final List<String> optionsMl;
  final String difficulty;
  final int order;

  const VideoQuestionItem({
    required this.id,
    this.videoId = '',
    this.type = 'mcq',
    required this.questionEn,
    required this.questionMl,
    required this.optionsEn,
    required this.optionsMl,
    this.difficulty = 'Easy',
    this.order = 0,
  });

  String questionFor(String locale) =>
      locale == 'ml' && questionMl.isNotEmpty ? questionMl : questionEn;

  List<String> optionsFor(String locale) =>
      locale == 'ml' &&
          optionsMl.length == optionsEn.length &&
          optionsMl.isNotEmpty
      ? optionsMl
      : optionsEn;

  static List<String> _options(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  factory VideoQuestionItem.fromJson(Map<String, dynamic> json) {
    return VideoQuestionItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      videoId: (json['videoId'] ?? '').toString(),
      type: (json['type'] ?? 'mcq').toString(),
      questionEn: (json['question_en'] ?? '').toString(),
      questionMl: (json['question_ml'] ?? '').toString(),
      optionsEn: _options(json['options_en']),
      optionsMl: _options(json['options_ml']),
      difficulty: (json['difficulty'] ?? 'Easy').toString(),
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A single graded question, as returned inside a [VideoQuizResult].
class VideoQuestionResult {
  final String questionId;
  final String type;
  final String questionEn;
  final String questionMl;
  final List<String> optionsEn;
  final List<String> optionsMl;
  final String attemptedAnswer;
  final String correctAnswer;
  final bool isCorrect;

  const VideoQuestionResult({
    required this.questionId,
    this.type = 'mcq',
    this.questionEn = '',
    this.questionMl = '',
    this.optionsEn = const [],
    this.optionsMl = const [],
    this.attemptedAnswer = '',
    this.correctAnswer = '',
    this.isCorrect = false,
  });

  String questionFor(String locale) =>
      locale == 'ml' && questionMl.isNotEmpty ? questionMl : questionEn;

  factory VideoQuestionResult.fromJson(Map<String, dynamic> json) {
    return VideoQuestionResult(
      questionId: (json['questionId'] ?? '').toString(),
      type: (json['type'] ?? 'mcq').toString(),
      questionEn: (json['question_en'] ?? '').toString(),
      questionMl: (json['question_ml'] ?? '').toString(),
      optionsEn: VideoQuestionItem._options(json['options_en']),
      optionsMl: VideoQuestionItem._options(json['options_ml']),
      attemptedAnswer: (json['attemptedAnswer'] ?? '').toString(),
      correctAnswer: (json['correctAnswer'] ?? '').toString(),
      isCorrect: json['isCorrect'] == true,
    );
  }
}

/// Result of answering a video's questions, graded on the server.
class VideoQuizResult {
  final String attemptId;
  final String videoId;
  final String language;
  final int score;
  final int totalQuestions;
  final int percentage;
  final DateTime? createdAt;
  final List<VideoQuestionResult> results;

  const VideoQuizResult({
    this.attemptId = '',
    this.videoId = '',
    this.language = 'en',
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    this.createdAt,
    this.results = const [],
  });

  factory VideoQuizResult.fromJson(Map<String, dynamic> json) {
    return VideoQuizResult(
      attemptId: (json['attemptId'] ?? '').toString(),
      videoId: (json['videoId'] ?? '').toString(),
      language: (json['language'] ?? 'en').toString(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      results: json['results'] is List
          ? (json['results'] as List)
                .whereType<Map>()
                .map(
                  (e) => VideoQuestionResult.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

/// Server-side "seen" flags + language preference (`/api/user/prefs`).
class UserPrefs {
  final List<String> seenGuides;
  final String language;

  const UserPrefs({this.seenGuides = const [], this.language = 'en'});

  factory UserPrefs.fromJson(Map<String, dynamic> json) {
    return UserPrefs(
      seenGuides: json['seenGuides'] is List
          ? (json['seenGuides'] as List).map((e) => e.toString()).toList()
          : const [],
      language: (json['language'] ?? 'en').toString(),
    );
  }
}

class VideoPracticeSettings {
  const VideoPracticeSettings({
    this.available = true,
    this.timerMode = 'none',
    this.overallTimeLimit,
    this.perQuestionTimeLimit,
  });

  final bool available;
  final String timerMode;
  final int? overallTimeLimit;
  final int? perQuestionTimeLimit;

  factory VideoPracticeSettings.fromJson(Map<String, dynamic> json) {
    return VideoPracticeSettings(
      available: json['available'] != false,
      timerMode: (json['timerMode'] ?? 'none').toString(),
      overallTimeLimit: (json['overallTimeLimit'] as num?)?.toInt(),
      perQuestionTimeLimit: (json['perQuestionTimeLimit'] as num?)?.toInt(),
    );
  }
}

class VideoProgressService {
  /// Watch state for one video, or null when unreachable / not signed in.
  static Future<VideoProgressStatus?> fetch(String videoId) async {
    try {
      final body = await ApiClient.get('/api/video-progress/$videoId');
      if (body is! Map) return null;
      return VideoProgressStatus.fromJson(Map<String, dynamic>.from(body));
    } catch (_) {
      return null;
    }
  }

  /// Builds the exact JSON body sent to `POST /api/video-progress`. Exposed
  /// separately (and pure/synchronous) so a test can assert its shape —
  /// notably that it never includes an `ended` key — without needing a
  /// network call.
  @visibleForTesting
  static Map<String, dynamic> heartbeatBody({
    required String videoId,
    required int position,
    required int watchedDelta,
    int? duration,
  }) {
    return {
      'videoId': videoId,
      'position': position,
      'watchedDelta': watchedDelta,
      if (duration != null) 'duration': duration,
    };
  }

  /// Tell the server how far the video has played.
  ///
  /// [watchedDelta] must be the seconds of *normal playback* since the last
  /// heartbeat — a seek is not counted, which is what makes skipping useless.
  /// There is no `ended` shortcut in the contract; completion is always
  /// decided by the server from watched seconds.
  static Future<VideoProgressStatus?> heartbeat({
    required String videoId,
    required int position,
    required int watchedDelta,
    int? duration,
  }) async {
    try {
      final body = await ApiClient.post(
        '/api/video-progress',
        body: heartbeatBody(
          videoId: videoId,
          position: position,
          watchedDelta: watchedDelta,
          duration: duration,
        ),
      );
      if (body is! Map) return null;
      return VideoProgressStatus.fromJson(Map<String, dynamic>.from(body));
    } catch (_) {
      return null;
    }
  }

  /// All video ids this user has progress on, keyed by video id.
  static Future<Map<String, VideoProgressStatus>> fetchAll() async {
    try {
      final body = await ApiClient.get('/api/video-progress');
      if (body is! List) return {};
      return {
        for (final item in body.whereType<Map>())
          (item['videoId'] ?? '').toString(): VideoProgressStatus.fromJson(
            Map<String, dynamic>.from(item),
          ),
      };
    } catch (_) {
      return {};
    }
  }

  /// Questions attached to a video (empty list when there are none). Never
  /// includes the correct answer.
  static Future<List<VideoQuestionItem>> questions(String videoId) async {
    try {
      final body = await ApiClient.get(
        '/api/video-questions',
        query: {'videoId': videoId},
      );
      if (body is! List) return [];
      return body
          .whereType<Map>()
          .map((e) => VideoQuestionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<VideoPracticeSettings> practiceSettings(String videoId) async {
    try {
      final body = await ApiClient.get(
        '/api/video-questions/settings',
        query: {'videoId': videoId},
      );
      if (body is Map) {
        return VideoPracticeSettings.fromJson(Map<String, dynamic>.from(body));
      }
    } catch (_) {}
    return const VideoPracticeSettings();
  }

  /// The signed-in user's existing attempt for this video, or null when they
  /// have not attempted it yet.
  static Future<VideoQuizResult?> existingAttempt(String videoId) async {
    try {
      final body = await ApiClient.get(
        '/api/user/video-quiz',
        query: {'videoId': videoId},
      );
      if (body is! Map) return null;
      return VideoQuizResult.fromJson(Map<String, dynamic>.from(body));
    } catch (_) {
      return null;
    }
  }

  /// Submit answers; the server grades them and returns the score.
  ///
  /// Throws [ApiException] on failure so the caller can distinguish
  /// "watch the video first" (403), "already attempted" (409, carries the
  /// prior [VideoQuizResult]) from a genuine error.
  static Future<VideoQuizResult> submit({
    required String videoId,
    required List<Map<String, String>> answers,
    String locale = 'en',
  }) async {
    final body = await ApiClient.post(
      '/api/user/video-quiz',
      body: {
        'videoId': videoId,
        // The server only recognizes the literal 'Malayalam' (anything else
        // is stored as 'English') — translate the locale code before sending
        // so the stored attempt.language matches what was actually taken.
        'language': locale == 'ml' ? 'Malayalam' : 'English',
        'answers': answers,
      },
    );
    final attempt = (body is Map && body['attempt'] is Map)
        ? body['attempt'] as Map
        : body;
    return VideoQuizResult.fromJson(Map<String, dynamic>.from(attempt as Map));
  }

  static Future<UserPrefs> fetchPrefs() async {
    try {
      final body = await ApiClient.get('/api/user/prefs');
      if (body is! Map) return const UserPrefs();
      return UserPrefs.fromJson(Map<String, dynamic>.from(body));
    } catch (_) {
      return const UserPrefs();
    }
  }

  static Future<UserPrefs> updatePrefs({
    List<String>? seenGuides,
    String? language,
  }) async {
    try {
      final body = await ApiClient.put(
        '/api/user/prefs',
        body: {
          if (seenGuides != null) 'seenGuides': seenGuides,
          if (language != null) 'language': language,
        },
      );
      if (body is! Map) return const UserPrefs();
      return UserPrefs.fromJson(Map<String, dynamic>.from(body));
    } catch (_) {
      return const UserPrefs();
    }
  }

  static Future<void> recordNoteRead(String videoId) async {
    try {
      await ApiClient.post(
        '/api/user/learning-stats/note-read',
        body: {'videoId': videoId},
      );
    } catch (_) {
      // Learning telemetry must never block opening a note.
    }
  }
}
