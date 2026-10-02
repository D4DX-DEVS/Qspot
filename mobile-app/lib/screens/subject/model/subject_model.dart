/// One line of the "what is inside" guide shown the first time a chapter opens.
class SubjectGuidePoint {
  final String icon;
  final String text;

  const SubjectGuidePoint({required this.icon, required this.text});

  factory SubjectGuidePoint.fromJson(Map<String, dynamic> json) {
    return SubjectGuidePoint(
      icon: (json['icon'] ?? 'info').toString(),
      text: (json['text'] ?? '').toString(),
    );
  }
}

class SubjectModel {
  static const String defaultGuideTitle = 'What Is Inside This Chapter';

  /// Used when the admin has not written a guide for this chapter yet, so the
  /// first-open panel is never empty.
  static const List<SubjectGuidePoint> defaultGuidePoints = [
    SubjectGuidePoint(
      icon: 'video',
      text: 'Watch the episodes in this chapter',
    ),
    SubjectGuidePoint(
      icon: 'quiz',
      text: 'Answer the questions at the end of a video',
    ),
    SubjectGuidePoint(
      icon: 'progress',
      text: 'Your progress is saved to your account',
    ),
  ];

  final String id;
  final String subject;
  final String? subImage;
  final int order;
  final String guideTitle;
  final List<SubjectGuidePoint> guidePoints;

  /// The course this subject belongs to, for grouping the Subjects tab (R1).
  final String? courseId;

  SubjectModel({
    required this.id,
    required this.subject,
    this.subImage,
    this.order = 0,
    this.guideTitle = defaultGuideTitle,
    this.guidePoints = defaultGuidePoints,
    this.courseId,
  });

  // Factory constructor for JSON deserialization
  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['guidePoints'];
    final parsed = rawPoints is List
        ? rawPoints
              .whereType<Map>()
              .map(
                (point) => SubjectGuidePoint.fromJson(
                  Map<String, dynamic>.from(point),
                ),
              )
              .where((point) => point.text.trim().isNotEmpty)
              .toList()
        : <SubjectGuidePoint>[];

    final rawTitle = (json['guideTitle'] ?? '').toString().trim();

    String? courseId = json['courseId']?.toString();
    if (courseId == null && json['course'] is Map) {
      courseId = (json['course'] as Map)['_id']?.toString();
    } else if (courseId == null && json['course'] != null) {
      courseId = json['course'].toString();
    }

    return SubjectModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '0',
      subject: (json['name'] ?? json['subject'])?.toString() ?? '',
      subImage: (json['image'] ?? json['sub_image'])?.toString(),
      order: (json['order'] as num?)?.toInt() ?? 0,
      guideTitle: rawTitle.isEmpty ? defaultGuideTitle : rawTitle,
      guidePoints: parsed.isEmpty ? defaultGuidePoints : parsed,
      courseId: courseId,
    );
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'subImage': subImage,
      'order': order,
      'guideTitle': guideTitle,
      'courseId': courseId,
      'guidePoints': guidePoints
          .map((point) => {'icon': point.icon, 'text': point.text})
          .toList(),
    };
  }

  // Helper method to get full image URL. The API always returns a full URL
  // for the subject cover image; when there is none, return null and let
  // the UI fall back to a local placeholder/icon instead of a third-party
  // URL.
  String? get imageUrl {
    if (subImage != null && subImage!.isNotEmpty) {
      if (subImage!.startsWith('http://') || subImage!.startsWith('https://')) {
        return subImage!;
      }
    }
    return null;
  }

  // Helper method to get the subject name in Title Case (each word
  // capitalized, not just the first letter of the whole string).
  String get displayName {
    if (subject.isEmpty) return 'Unknown Subject';
    return subject
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  // Helper method to get subject ID as string
  String get subjectId => id;
}
