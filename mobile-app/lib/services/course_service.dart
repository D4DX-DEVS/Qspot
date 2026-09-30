import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// A course the app is running, shown on the Home screen and explained in the
/// "About this course" popup.
class CourseModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final List<String> learnPoints;
  final String image;

  const CourseModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.learnPoints = const [],
    this.image = '',
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    final points = json['learnPoints'];
    return CourseModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      learnPoints: points is List
          ? points
                .map((point) => point.toString().trim())
                .where((p) => p.isNotEmpty)
                .toList()
          : const [],
      image: (json['image'] ?? '').toString(),
    );
  }
}

class CourseService {
  /// Courses that are currently running (`GET /api/courses` already returns
  /// only active ones — see the contract). Returns an empty list when the
  /// endpoint is unreachable, so Home/Subjects simply hide that section.
  static Future<List<CourseModel>> fetchActive({
    bool forSelection = false,
  }) async {
    try {
      final body = await ApiClient.get(
        '/api/courses',
        query: forSelection ? {'forSelection': true} : null,
      );
      if (body is! List) return [];
      return body
          .whereType<Map>()
          .map((json) => CourseModel.fromJson(Map<String, dynamic>.from(json)))
          .where((course) => course.title.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('📚 [COURSES] fetch failed: $e');
      return [];
    }
  }
}
