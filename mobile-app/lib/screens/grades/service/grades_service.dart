import 'package:flutter/foundation.dart';

import '../../../services/api_client.dart';
import '../../../utils/json_parsing.dart';
import '../../assignment/model/assignment_model.dart';
import '../../assignment/service/assignment_service.dart';
import '../model/grade_entry.dart';
import '../model/grade_kind.dart';

/// Gathers a learner's marks from the places the server keeps them: quiz and
/// lesson-practice attempts, and assignments a teacher has marked.
class GradesService {
  const GradesService._();

  /// Quiz and lesson-practice marks from a `GET /api/user/progress` body.
  static List<GradeEntry> fromProgress(dynamic body) {
    if (body is! Map) return const [];
    return [
      ..._attempts(body['quizAttempts'], GradeKind.quiz),
      ..._attempts(body['videoQuizzes'], GradeKind.lessonPractice),
    ];
  }

  /// Marks for the assignments a teacher has marked. Work that is handed in
  /// but not marked yet is left out.
  static List<GradeEntry> fromAssignments(Iterable<AssignmentModel> items) => [
    for (final item in items)
      if (item.isGraded)
        GradeEntry(
          kind: GradeKind.assignment,
          title: item.title,
          score: item.gradePoints!,
          outOf: item.maxPoints,
          date: item.gradedAt ?? item.submittedAt,
          subjectId: item.subjectId,
          courseId: item.courseId,
          feedback: item.feedback.trim(),
        ),
  ];

  /// Every mark the learner has. Fails only when the quiz and practice marks
  /// cannot be loaded; a failed assignment list leaves those marks out.
  static Future<List<GradeEntry>> fetch() async {
    final results = await Future.wait([
      ApiClient.get('/api/user/progress'),
      _assignments(),
    ]);
    return [
      ...fromProgress(results[0]),
      ...fromAssignments(results[1] as List<AssignmentModel>),
    ];
  }

  static Future<List<AssignmentModel>> _assignments() async {
    try {
      return await AssignmentService.fetchAll();
    } catch (error) {
      debugPrint('Assignment marks unavailable: $error');
      return const [];
    }
  }

  static List<GradeEntry> _attempts(dynamic value, GradeKind kind) {
    if (value is! List) return const [];
    return [
      for (final item in value.whereType<Map>())
        if ((item['title'] ?? '').toString().isNotEmpty)
          GradeEntry(
            kind: kind,
            title: item['title'].toString(),
            score: jsonInt(item['score']) ?? 0,
            outOf: jsonInt(item['totalQuestions']) ?? 0,
            date: DateTime.tryParse((item['createdAt'] ?? '').toString()),
            videoId: kind == GradeKind.lessonPractice
                ? item['videoId']?.toString()
                : null,
          ),
    ];
  }
}
