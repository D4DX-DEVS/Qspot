class QuestionModel {
  final String? id;
  final String subject;
  final String description;
  final String faculty;
  final DateTime? dateCreated;

  QuestionModel({
    this.id,
    required this.subject,
    required this.description,
    required this.faculty,
    this.dateCreated,
  });

  // Factory constructor for JSON deserialization
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id']?.toString(),
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      faculty: json['faculty']?.toString() ?? '',
      dateCreated: json['date_created'] != null
          ? DateTime.parse(json['date_created'])
          : null,
    );
  }

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'subject': subject,
      'description': description,
      'faculty': faculty,
    };

    if (id != null) {
      map['id'] = id;
    }

    if (dateCreated != null) {
      map['date_created'] = dateCreated!.toIso8601String();
    }

    return map;
  }
}
