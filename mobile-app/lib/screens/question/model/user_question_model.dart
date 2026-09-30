// Model for User Question with Answer
class UserQuestion {
  final String id;
  final String subject;
  final String description;
  final String facultyId;
  final String facultyName;
  final String? facultyDesignation;
  final String userId;
  final String userName;
  final String? userClass;
  final String? answer;
  final String? answeredBy;
  final DateTime? answeredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserQuestion({
    required this.id,
    required this.subject,
    required this.description,
    required this.facultyId,
    required this.facultyName,
    this.facultyDesignation,
    required this.userId,
    required this.userName,
    this.userClass,
    this.answer,
    this.answeredBy,
    this.answeredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserQuestion.fromJson(Map<String, dynamic> json) {
    final faculty = json['faculty'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;

    return UserQuestion(
      id: json['_id']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      facultyId: faculty?['_id']?.toString() ?? '',
      facultyName: faculty?['name']?.toString() ?? 'Unknown Faculty',
      facultyDesignation: faculty?['designation']?.toString(),
      userId: user?['_id']?.toString() ?? '',
      userName: user?['name']?.toString() ?? 'Unknown User',
      userClass: user?['class']?.toString(),
      answer: json['answer']?.toString(),
      answeredBy: json['answeredBy']?.toString(),
      answeredAt: json['answeredAt'] != null
          ? DateTime.parse(json['answeredAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}
