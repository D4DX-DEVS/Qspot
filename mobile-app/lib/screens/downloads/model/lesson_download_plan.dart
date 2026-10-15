import '../../video/model/video_model.dart';

/// One file a lesson can save for offline use.
class PlannedFile {
  const PlannedFile({
    required this.url,
    required this.name,
    required this.kind,
  });

  final String url;
  final String name;

  /// `video` or `handout`.
  final String kind;
}

/// Which of a lesson's files can be saved on the phone. YouTube lessons and
/// live streams can't (YouTube doesn't allow it); their handouts can.
class LessonDownloadPlan {
  LessonDownloadPlan._();

  static bool isSavableVideo(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !const {'http', 'https'}.contains(uri.scheme)) {
      return false;
    }
    return !uri.host.contains('youtube.com') && !uri.host.contains('youtu.be');
  }

  static List<PlannedFile> filesFor(VideoModel video) => [
    if (isSavableVideo(video.videoUrl))
      PlannedFile(url: video.videoUrl, name: video.displayTitle, kind: 'video'),
    for (final handout in video.downloads)
      if (Uri.tryParse(handout.resolvedUrl)?.hasScheme ?? false)
        PlannedFile(
          url: handout.resolvedUrl,
          name: handout.title,
          kind: 'handout',
        ),
  ];

  static bool hasVideo(VideoModel video) => isSavableVideo(video.videoUrl);
}
