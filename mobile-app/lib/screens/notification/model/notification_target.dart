/// The screen a notification opens when tapped.
class NotificationTarget {
  const NotificationTarget({required this.kind, required this.id});

  /// `lesson`, `quiz`, `assignment` or `course`.
  final String kind;
  final String id;

  static const kinds = {'lesson', 'quiz', 'assignment', 'course'};

  /// Null when the notification opens nothing (`{kind: 'none'}`) or the
  /// payload is not understood.
  static NotificationTarget? fromJson(Object? json) {
    if (json is! Map) return null;
    final kind = (json['kind'] ?? '').toString();
    final id = (json['id'] ?? '').toString();
    if (!kinds.contains(kind) || id.isEmpty) return null;
    return NotificationTarget(kind: kind, id: id);
  }
}
