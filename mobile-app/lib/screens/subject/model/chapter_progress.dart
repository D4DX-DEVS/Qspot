/// Where a learner stands in one chapter.
enum ChapterStatus { empty, notStarted, inProgress, completed }

/// Lesson counts for one chapter: how many are available, how many are
/// finished and how many are begun but not finished.
class ChapterProgress {
  const ChapterProgress({
    required this.total,
    this.completed = 0,
    this.started = 0,
  });

  static const ChapterProgress none = ChapterProgress(total: 0);

  final int total;
  final int completed;

  /// Lessons watched part of the way, not counting finished ones.
  final int started;

  /// 0 to 1, the share of lessons finished.
  double get fraction =>
      total == 0 ? 0 : (completed / total).clamp(0.0, 1.0).toDouble();

  ChapterStatus get status {
    if (total == 0) return ChapterStatus.empty;
    if (completed >= total) return ChapterStatus.completed;
    if (completed > 0 || started > 0) return ChapterStatus.inProgress;
    return ChapterStatus.notStarted;
  }
}
