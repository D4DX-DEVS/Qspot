import '../../../services/video_progress_service.dart';
import '../../video/model/video_model.dart';

/// How many lessons the learner can open now, and how many of those are
/// finished. Lessons that open later are left out, and so is progress on
/// lessons that are not in [LessonCounts.from]'s list (for example a course
/// the learner has since left), so the count can never pass the total.
class LessonCounts {
  const LessonCounts({required this.completed, required this.total});

  final int completed;
  final int total;

  factory LessonCounts.from(
    Iterable<VideoModel> videos,
    Map<String, VideoProgressStatus> progressByVideo,
  ) {
    var total = 0;
    var completed = 0;
    for (final video in videos) {
      if (video.isUpcoming) continue;
      total++;
      if (progressByVideo[video.id]?.completed == true) completed++;
    }
    return LessonCounts(completed: completed, total: total);
  }

  /// "3/48", as shown on the Today stat tile.
  String get label => '$completed/$total';
}
