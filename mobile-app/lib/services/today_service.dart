import 'package:flutter/foundation.dart';

import 'api_client.dart';
import '../utils/json_parsing.dart';

class TodayLearningItem {
  const TodayLearningItem({
    required this.kind,
    required this.id,
    required this.title,
    required this.status,
    this.subject = '',
    this.releaseAt,
    this.dueAt,
    this.assessmentType = 'quiz',
    this.percent,
    this.estimatedMinutes,
  });

  final String kind;
  final String id;
  final String title;
  final String status;
  final String subject;
  final DateTime? releaseAt;
  final DateTime? dueAt;
  final String assessmentType;
  final double? percent;
  final int? estimatedMinutes;

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double? _number(dynamic value) {
    return jsonDouble(value);
  }

  static int? _integer(dynamic value) {
    return jsonInt(value);
  }

  factory TodayLearningItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    final rawSubject = json['subject'];
    return TodayLearningItem(
      kind: (json['kind'] ?? '').toString(),
      id: rawId?.toString() ?? '',
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      subject: rawSubject is Map
          ? (rawSubject['name'] ?? '').toString()
          : (rawSubject ?? '').toString(),
      releaseAt: _date(json['releaseAt']),
      dueAt: _date(json['dueAt']),
      assessmentType: (json['assessmentType'] ?? 'quiz').toString(),
      percent: _number(json['percent'])?.clamp(0, 100).toDouble(),
      estimatedMinutes: _integer(json['estimatedMinutes']),
    );
  }
}

class TodayOverview {
  const TodayOverview({
    this.next,
    this.continueItems = const [],
    this.upcoming = const [],
    this.currentStreak,
    this.bestStreak,
    this.summary = '',
  });

  final TodayLearningItem? next;
  final List<TodayLearningItem> continueItems;
  final List<TodayLearningItem> upcoming;
  final int? currentStreak;
  final int? bestStreak;
  final String summary;

  static List<TodayLearningItem> _items(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => TodayLearningItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static int? _streakValue(Map<String, dynamic> streak, List<String> keys) {
    for (final key in keys) {
      final value = streak[key];
      final parsed = jsonInt(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  factory TodayOverview.fromJson(Map<String, dynamic> json) {
    final rawNext = json['next'];
    final rawStreak = json['streak'];
    final streak = rawStreak is Map
        ? Map<String, dynamic>.from(rawStreak)
        : <String, dynamic>{};
    final rawSummary = json['summary'];
    final summary = rawSummary is String
        ? rawSummary
        : rawSummary is Map
        ? (rawSummary['text'] ?? rawSummary['message'] ?? '').toString()
        : '';

    return TodayOverview(
      next: rawNext is Map
          ? TodayLearningItem.fromJson(Map<String, dynamic>.from(rawNext))
          : null,
      continueItems: _items(json['continue']),
      upcoming: _items(json['upcoming']),
      currentStreak: rawStreak is num
          ? jsonInt(rawStreak)
          : _streakValue(streak, const ['current', 'currentStreak', 'days']),
      bestStreak: _streakValue(streak, const ['best', 'bestStreak']),
      summary: summary,
    );
  }
}

class TodayService {
  static Future<TodayOverview?> fetch() async {
    try {
      final body = await ApiClient.get(
        '/api/user/today',
        query: {'tzOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes},
      );
      if (body is! Map) return null;
      return TodayOverview.fromJson(Map<String, dynamic>.from(body));
    } catch (error) {
      debugPrint('Today overview unavailable: $error');
      return null;
    }
  }
}
