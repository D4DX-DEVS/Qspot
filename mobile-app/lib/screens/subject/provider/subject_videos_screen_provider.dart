import 'package:flutter/foundation.dart';

import '../../../services/api_client.dart';
import '../../video/model/video_model.dart';

/// Screen-local state for the subject videos screen: the chapter's videos and
/// their loading / error status.
class SubjectVideosScreenProvider extends ChangeNotifier {
  List<VideoModel> _videos = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _disposed = false;

  List<VideoModel> get videos => _videos;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  /// Fetches only this subject's videos server-side (`?subject=<id>`) instead
  /// of downloading the full catalogue and filtering client-side (M12).
  /// [onLoaded] runs after the videos are shown; a failure in it is reported
  /// as a load error, like a failure of the fetch itself.
  Future<void> loadSubjectVideos(
    String subjectId, {
    Future<void> Function()? onLoaded,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final body = await ApiClient.get(
        '/api/videos',
        query: {'subject': subjectId},
      );
      final List<dynamic> videosJson = body is List ? body : const [];
      final videos = videosJson
          .whereType<Map>()
          .map((json) => VideoModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      // Episodes within a subject ordered by their `order` field (R4), not
      // creation time.
      videos.sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        if (byOrder != 0) return byOrder;
        return b.datePublished.compareTo(a.datePublished);
      });

      debugPrint('📚 [SUBJECT VIDEOS] Loaded ${videos.length} for $subjectId');

      if (_disposed) return;
      _videos = videos;
      _isLoading = false;
      notifyListeners();

      await onLoaded?.call();
    } catch (e) {
      debugPrint('📚 [SUBJECT VIDEOS] Error: $e');
      if (_disposed) return;
      _errorMessage = 'Failed to load videos: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
