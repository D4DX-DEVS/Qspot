import 'package:flutter/foundation.dart';

import 'api_client.dart';

class MasteryItem {
  const MasteryItem({
    required this.id,
    required this.title,
    required this.total,
    required this.completed,
  });

  final String id;
  final String title;
  final int total;
  final int completed;

  double get percent {
    if (total <= 0) return 0;
    return (completed / total).clamp(0.0, 1.0);
  }

  factory MasteryItem.fromJson(
    Map<String, dynamic> json, {
    required String idKey,
  }) {
    final total = (json['total'] as num?)?.toInt() ?? 0;
    final completed = (json['completed'] as num?)?.toInt() ?? 0;
    return MasteryItem(
      id: (json[idKey] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? 'Untitled').toString(),
      total: total,
      completed: completed.clamp(0, total < 0 ? 0 : total).toInt(),
    );
  }
}

class ProgressActivity {
  const ProgressActivity({
    required this.kind,
    required this.title,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    this.createdAt,
  });

  final String kind;
  final String title;
  final int score;
  final int totalQuestions;
  final num percentage;
  final DateTime? createdAt;

  bool get isVideoQuiz => kind == 'video-quiz';

  factory ProgressActivity.fromJson(
    Map<String, dynamic> json, {
    required String kind,
  }) {
    return ProgressActivity(
      kind: kind,
      title: (json['title'] ?? '').toString(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?) ?? 0,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

class LearningStats {
  const LearningStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.xp = 0,
    this.level = 1,
    this.lastActivityDate,
  });

  final int currentStreak;
  final int longestStreak;
  final int xp;
  final int level;
  final DateTime? lastActivityDate;

  factory LearningStats.fromJson(Map<String, dynamic> json) {
    return LearningStats(
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: ((json['level'] as num?)?.toInt() ?? 1).clamp(1, 999).toInt(),
      lastActivityDate: DateTime.tryParse(
        '${json['lastActivityDate'] ?? ''}T00:00:00',
      ),
    );
  }
}

class LearningProgressData {
  const LearningProgressData({
    this.videosTotal = 0,
    this.videosCompleted = 0,
    this.videosInProgress = 0,
    this.courses = const [],
    this.subjects = const [],
    this.activities = const [],
    this.stats,
  });

  final int videosTotal;
  final int videosCompleted;
  final int videosInProgress;
  final List<MasteryItem> courses;
  final List<MasteryItem> subjects;
  final List<ProgressActivity> activities;
  final LearningStats? stats;

  double get masteryPercent {
    if (videosTotal <= 0) return 0;
    return (videosCompleted / videosTotal).clamp(0.0, 1.0);
  }

  factory LearningProgressData.fromJson(
    Map<String, dynamic> progress,
    Map<String, dynamic>? statsJson,
  ) {
    final videos = progress['videos'] is Map
        ? Map<String, dynamic>.from(progress['videos'] as Map)
        : <String, dynamic>{};

    List<ProgressActivity> parseActivities(dynamic value, String kind) {
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map(
            (item) => ProgressActivity.fromJson(
              Map<String, dynamic>.from(item),
              kind: kind,
            ),
          )
          .where((item) => item.title.isNotEmpty)
          .toList();
    }

    List<MasteryItem> parseMastery(dynamic value, String idKey) {
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map(
            (item) => MasteryItem.fromJson(
              Map<String, dynamic>.from(item),
              idKey: idKey,
            ),
          )
          .where((item) => item.id.isNotEmpty && item.total > 0)
          .toList()
        ..sort((a, b) => b.percent.compareTo(a.percent));
    }

    final activities =
        [
          ...parseActivities(progress['quizAttempts'], 'quiz'),
          ...parseActivities(progress['videoQuizzes'], 'video-quiz'),
        ]..sort((a, b) {
          final aDate = a.createdAt;
          final bDate = b.createdAt;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

    return LearningProgressData(
      videosTotal: (videos['total'] as num?)?.toInt() ?? 0,
      videosCompleted: (videos['completed'] as num?)?.toInt() ?? 0,
      videosInProgress: (videos['inProgress'] as num?)?.toInt() ?? 0,
      courses: parseMastery(progress['courses'], 'courseId'),
      subjects: parseMastery(progress['subjects'], 'subjectId'),
      activities: activities,
      stats: statsJson == null ? null : LearningStats.fromJson(statsJson),
    );
  }
}

class LearningProgressService {
  const LearningProgressService._();

  static Future<LearningProgressData> fetch() async {
    final results = await Future.wait([
      ApiClient.get('/api/user/progress'),
      _fetchStats(),
    ]);
    final progress = results[0];
    if (progress is! Map) {
      throw const FormatException('Invalid progress response');
    }
    final stats = results[1];
    return LearningProgressData.fromJson(
      Map<String, dynamic>.from(progress),
      stats is Map ? Map<String, dynamic>.from(stats) : null,
    );
  }

  static Future<dynamic> _fetchStats() async {
    try {
      return await ApiClient.get(
        '/api/user/learning-stats',
        query: {'tzOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes},
      );
    } catch (error) {
      debugPrint('Learning stats unavailable: $error');
      return null;
    }
  }
}
