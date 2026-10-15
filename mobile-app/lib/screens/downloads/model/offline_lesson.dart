import 'offline_file.dart';

/// A lesson saved on the phone: its video (when it isn't on YouTube) and
/// its handouts.
class OfflineLesson {
  const OfflineLesson({
    required this.lessonId,
    required this.title,
    required this.files,
    required this.savedAt,
  });

  final String lessonId;
  final String title;
  final List<OfflineFile> files;
  final DateTime savedAt;

  int get bytes => files.fold(0, (sum, f) => sum + f.bytes);
  bool get hasVideo => files.any((f) => f.isVideo);
  int get handoutCount => files.where((f) => !f.isVideo).length;

  /// "Video + 2 handouts", "3 handouts" or "Video".
  String get contentsLabel {
    final handouts = handoutCount == 0
        ? ''
        : '$handoutCount handout${handoutCount == 1 ? '' : 's'}';
    if (!hasVideo) return handouts;
    return handouts.isEmpty ? 'Video' : 'Video + $handouts';
  }

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'title': title,
    'files': files.map((f) => f.toJson()).toList(),
    'savedAt': savedAt.toIso8601String(),
  };

  factory OfflineLesson.fromJson(Map<String, dynamic> json) => OfflineLesson(
    lessonId: (json['lessonId'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    files: json['files'] is List
        ? (json['files'] as List)
              .whereType<Map>()
              .map((f) => OfflineFile.fromJson(Map<String, dynamic>.from(f)))
              .toList()
        : const [],
    savedAt:
        DateTime.tryParse((json['savedAt'] ?? '').toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}
