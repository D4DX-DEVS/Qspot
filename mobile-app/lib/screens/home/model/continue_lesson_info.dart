import '../../../services/video_progress_service.dart';
import '../../video/model/video_model.dart';

/// What the "Jump Back In" card says about a lesson: a short, upbeat status
/// with an emoji and how much is left to watch.
class ContinueLessonInfo {
  const ContinueLessonInfo({
    required this.progress,
    required this.completed,
    required this.emoji,
    required this.label,
    this.timeLeft,
  });

  /// 0..1 watched, from where playback stopped.
  final double progress;
  final bool completed;
  final String emoji;
  final String label;

  /// e.g. "4 Min Left". Null when finished or when the length is unknown.
  final String? timeLeft;

  factory ContinueLessonInfo.from(
    VideoModel video,
    VideoProgressStatus? status,
  ) {
    final completed = status?.completed == true;
    final progress = (status?.percent ?? 0).clamp(0.0, 1.0);
    final (emoji, label) = completed
        ? ('✅', 'Nailed It')
        : progress >= 0.75
        ? ('🔥', 'Almost There')
        : progress >= 0.25
        ? ('⚡', 'Keep Going')
        : ('🚀', 'Just Started');
    return ContinueLessonInfo(
      progress: progress,
      completed: completed,
      emoji: emoji,
      label: label,
      timeLeft: completed ? null : _timeLeft(video, status),
    );
  }

  static String? _timeLeft(VideoModel video, VideoProgressStatus? status) {
    final duration = (status?.durationSeconds ?? 0) > 0
        ? status!.durationSeconds
        : video.durationSeconds;
    final left = duration - (status?.positionSeconds ?? 0);
    if (duration <= 0 || left <= 0) return null;
    return '${(left / 60).ceil()} Min Left';
  }
}
