import 'rubric_score.dart';

class AssignmentModel {
  const AssignmentModel({
    required this.id,
    required this.title,
    this.instructions = '',
    this.subject = '',
    this.status = 'open',
    this.dueAt,
    this.submissionText = '',
    this.submittedAt,
    this.feedback = '',
    this.grade,
    this.allowedMimeTypes = const [],
    this.maxFileSizeBytes = 10 * 1024 * 1024,
    this.submissionFiles = const [],
    this.courseId,
    this.subjectId,
    this.maxPoints = 100,
    this.gradedAt,
    this.rubricScores = const [],
  });

  final String id;
  final String title;
  final String instructions;
  final String subject;
  final String status;
  final DateTime? dueAt;
  final String submissionText;
  final DateTime? submittedAt;
  final String feedback;
  final String? grade;
  final List<String> allowedMimeTypes;
  final int maxFileSizeBytes;
  final List<AssignmentFileModel> submissionFiles;

  /// The course and chapter the teacher linked it to, when they did.
  final String? courseId;
  final String? subjectId;

  /// What the assignment is marked out of.
  final num maxPoints;

  /// When the teacher marked it, once they have.
  final DateTime? gradedAt;

  /// The score for each part when the work was marked by parts; empty when
  /// it was given one mark.
  final List<RubricScore> rubricScores;

  /// The server sends a link either as an id or as the linked record.
  static String? _linkId(dynamic value) {
    final id = value is Map ? (value['_id'] ?? value['id']) : value;
    final text = id?.toString() ?? '';
    return text.isEmpty ? null : text;
  }

  static num _points(dynamic value) {
    final points = num.tryParse('${value ?? ''}');
    return points != null && points > 0 ? points : 100;
  }

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    final rawSubmission = json['submission'];
    final submission = rawSubmission is Map
        ? Map<String, dynamic>.from(rawSubmission)
        : <String, dynamic>{};
    // The server sends the chapter filled in under subjectId ({_id, name});
    // a bare id there is not a name.
    final rawSubject =
        json['subject'] ??
        (json['subjectId'] is Map ? json['subjectId'] : null);
    final subject = rawSubject is Map
        ? (rawSubject['name'] ?? '').toString()
        : (rawSubject ?? json['subjectName'] ?? '').toString();

    return AssignmentModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? 'Assignment').toString(),
      instructions: (json['instructions'] ?? json['description'] ?? '')
          .toString(),
      subject: subject,
      status: (json['status'] ?? submission['status'] ?? 'open').toString(),
      dueAt: _date(json['dueAt'] ?? json['dueDate']),
      submissionText: (json['submissionText'] ?? submission['text'] ?? '')
          .toString(),
      submittedAt: _date(json['submittedAt'] ?? submission['submittedAt']),
      feedback: (json['feedback'] ?? submission['feedback'] ?? '').toString(),
      grade: (json['grade'] ?? submission['grade'])?.toString(),
      rubricScores: RubricScore.listFrom(
        json['rubricScores'] ?? submission['rubricScores'],
      ),
      allowedMimeTypes:
          (json['allowedMimeTypes'] is List
                  ? json['allowedMimeTypes'] as List
                  : const [])
              .map((value) => value.toString())
              .toList(),
      maxFileSizeBytes:
          int.tryParse((json['maxFileSizeBytes'] ?? '').toString()) ??
          10 * 1024 * 1024,
      submissionFiles:
          (submission['files'] is List ? submission['files'] as List : const [])
              .whereType<Map>()
              .map(
                (file) => AssignmentFileModel.fromJson(
                  Map<String, dynamic>.from(file),
                ),
              )
              .toList(),
      courseId: _linkId(json['courseId']),
      subjectId: _linkId(json['subjectId']),
      maxPoints: _points(json['maxPoints']),
      gradedAt: _date(json['gradedAt'] ?? submission['gradedAt']),
    );
  }

  /// The teacher sent the work back for changes: it is to do again.
  bool get isReturned => status.toLowerCase() == 'returned';

  bool get isSubmitted =>
      !isReturned &&
      (submittedAt != null ||
          const {
            'submitted',
            'graded',
            'reviewed',
            'complete',
            'completed',
          }.contains(status.toLowerCase()));

  /// The teacher's mark in points, or null until it has been marked.
  num? get gradePoints => num.tryParse(grade ?? '');

  bool get isGraded => gradePoints != null;

  /// The teacher has marked the work (a resubmission clears the mark).
  bool get isReviewed =>
      isGraded || const {'graded', 'reviewed'}.contains(status.toLowerCase());

  bool get isOverdue =>
      !isSubmitted && dueAt != null && dueAt!.isBefore(DateTime.now());

  /// The deadline has passed, so the work can no longer be sent. Work the
  /// teacher sent back for changes can still be sent again.
  bool get isClosed => isOverdue && !isReturned;
}

class AssignmentFileModel {
  const AssignmentFileModel({
    required this.name,
    required this.url,
    required this.mimeType,
    required this.size,
  });

  final String name;
  final String url;
  final String mimeType;
  final int size;

  factory AssignmentFileModel.fromJson(Map<String, dynamic> json) {
    return AssignmentFileModel(
      name: (json['name'] ?? 'Attachment').toString(),
      url: (json['url'] ?? '').toString(),
      mimeType: (json['mimeType'] ?? 'application/octet-stream').toString(),
      size: int.tryParse((json['size'] ?? 0).toString()) ?? 0,
    );
  }
}
