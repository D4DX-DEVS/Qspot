import '../../video/model/video_model.dart';

/// A bookmarked episode. The server now owns bookmarks (see
/// `GET/PUT/DELETE /api/user/bookmarks`) and returns the full public video
/// object for each one — there is no separate bookmark row, so this is a
/// thin wrapper around [VideoModel] rather than its own local record.
class BookmarkModel {
  final VideoModel video;

  BookmarkModel({required this.video});

  factory BookmarkModel.fromVideo(VideoModel video) =>
      BookmarkModel(video: video);

  factory BookmarkModel.fromJson(Map<String, dynamic> json) =>
      BookmarkModel(video: VideoModel.fromJson(json));

  String get videoId => video.id;
  String get videoTitle => video.displayTitle;
  String get videoCaption => video.caption;
  String? get videoThumbnail =>
      video.thumbnailUrl.isEmpty ? null : video.thumbnailUrl;
  String get videoUrl => video.video;

  VideoModel toVideoModel() => video;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookmarkModel && other.videoId == videoId;
  }

  @override
  int get hashCode => videoId.hashCode;
}
