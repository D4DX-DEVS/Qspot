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

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    final rawSubmission = json['submission'];
    final submission = rawSubmission is Map
        ? Map<String, dynamic>.from(rawSubmission)
        : <String, dynamic>{};
    final rawSubject = json['subject'];
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
      allowedMimeTypes: (json['allowedMimeTypes'] is List
              ? json['allowedMimeTypes'] as List
              : const [])
          .map((value) => value.toString())
          .toList(),
      maxFileSizeBytes:
          int.tryParse((json['maxFileSizeBytes'] ?? '').toString()) ??
          10 * 1024 * 1024,
      submissionFiles: (submission['files'] is List
              ? submission['files'] as List
              : const [])
          .whereType<Map>()
          .map(
            (file) => AssignmentFileModel.fromJson(
              Map<String, dynamic>.from(file),
            ),
          )
          .toList(),
    );
  }

  bool get isSubmitted =>
      submittedAt != null ||
      const {
        'submitted',
        'graded',
        'reviewed',
        'complete',
        'completed',
      }.contains(status.toLowerCase());

  bool get isOverdue =>
      !isSubmitted && dueAt != null && dueAt!.isBefore(DateTime.now());
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
