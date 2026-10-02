import 'package:flutter/foundation.dart';

import '../model/video_model.dart';
import '../../subject/model/chapter_progress.dart';
import '../../../services/api_client.dart';
import '../../../services/common/storage_service.dart';
import '../../../services/video_progress_service.dart';

enum VideoLoadingState { idle, loading, loaded, error }

class VideoProvider with ChangeNotifier {
  // State variables
  VideoLoadingState _loadingState = VideoLoadingState.idle;
  String _errorMessage = '';

  // Video data
  VideoModel? _latestVideo;
  List<VideoModel> _videosByDate = [];
  List<VideoModel> _allVideos = [];

  // True once `/api/videos` has been fetched at least once this app session.
  // Every screen re-uses this cache (see M12) — only pull-to-refresh, or the
  // explicit [refresh] call, hits the network again.
  bool _fetchedThisSession = false;

  // Search data
  List<VideoModel> _searchResults = [];
  String _searchQuery = '';

  // Currently playing video
  VideoModel? _currentlyPlaying;

  // Server-side watch state per video (status: not-started / in-progress /
  // completed). Empty when nobody is signed in.
  Map<String, VideoProgressStatus> _progressByVideo = {};

  // Getters
  VideoLoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;
  VideoModel? get latestVideo => _latestVideo;
  List<VideoModel> get videosByDate => _videosByDate;
  List<VideoModel> get allVideos => _allVideos;
  List<VideoModel> get searchResults => _searchResults;
  String get searchQuery => _searchQuery;
  VideoModel? get currentlyPlaying => _currentlyPlaying;
  Map<String, VideoProgressStatus> get progressByVideo => _progressByVideo;
  VideoProgressStatus? progressFor(String videoId) => _progressByVideo[videoId];

  /// Loads a known list without hitting the API (widget tests).
  @visibleForTesting
  void seedVideos(List<VideoModel> videos) {
    _allVideos = [...videos];
    _videosByDate = [...videos];
    _fetchedThisSession = true;
    notifyListeners();
  }

  /// Episodes presented by one faculty member, newest first.
  List<VideoModel> videosForSpeaker(String speakerId) {
    return _allVideos.where((video) => video.speakerId == speakerId).toList()
      ..sort((a, b) => b.datePublished.compareTo(a.datePublished));
  }

  /// Episodes belonging to one subject, ordered by their `order` field (not
  /// createdAt) — see R4.
  List<VideoModel> videosForSubject(String subjectId) {
    final videos = _allVideos
        .where((video) => video.subjectId == subjectId)
        .toList();
    videos.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      if (byOrder != 0) return byOrder;
      return b.datePublished.compareTo(a.datePublished);
    });
    return videos;
  }

  /// Finished and begun lesson counts for one subject. Upcoming episodes are
  /// left out: they cannot be played yet.
  ChapterProgress chapterProgressFor(String subjectId) {
    var total = 0;
    var completed = 0;
    var started = 0;
    for (final video in _allVideos) {
      if (video.subjectId != subjectId || video.isUpcoming) continue;
      total++;
      final progress = _progressByVideo[video.id];
      if (progress == null) continue;
      if (progress.completed) {
        completed++;
      } else if (progress.positionSeconds > 0) {
        started++;
      }
    }
    return ChapterProgress(
      total: total,
      completed: completed,
      started: started,
    );
  }

  bool get isLoading => _loadingState == VideoLoadingState.loading;
  bool get hasError => _loadingState == VideoLoadingState.error;
  bool get isEmpty =>
      _allVideos.isEmpty && _loadingState == VideoLoadingState.loaded;
  bool get isSearching => _searchQuery.isNotEmpty;

  // Initialize and load all video data. Only hits the network once per app
  // session (subsequent calls from other screens just reuse `_allVideos`).
  Future<void> initialize() async {
    if (_fetchedThisSession) {
      // Already loaded earlier this session; just refresh watch status.
      await loadProgress();
      return;
    }

    await _setLoadingState(VideoLoadingState.loading);

    try {
      await _loadFromCache();
      await _fetchAllVideos();
      // Watch status comes from the account, not the device.
      await loadProgress();
      await _setLoadingState(VideoLoadingState.loaded);
    } catch (e) {
      await _handleError('Failed to initialize videos: $e');
    }
  }

  /// Refresh the per-video watch status for the signed-in user. Also used to
  /// seed each player's resume position from the server (M14) — callers
  /// should read [progressFor] after this resolves rather than any local
  /// on-device cache.
  Future<void> loadProgress() async {
    final progress = await VideoProgressService.fetchAll();
    _progressByVideo = progress;
    notifyListeners();
  }

  // Fetch all videos from API - single call, contract shape (bare array).
  Future<List<VideoModel>> _fetchVideosFromAPI() async {
    final response = await ApiClient.get('/api/videos');
    final List<dynamic> videosJson = response is List ? response : const [];
    return videosJson
        .whereType<Map>()
        .map((json) => VideoModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  // Fetch + partition everything from one network call.
  Future<void> _fetchAllVideos() async {
    final videos = await _fetchVideosFromAPI();

    // Sort all videos by date (newest first, including both available and
    // upcoming), videos without dates last.
    final videosWithDates = videos.where((video) => video.date != null).toList()
      ..sort((a, b) => b.date!.compareTo(a.date!));
    final videosWithoutDates = videos
        .where((video) => video.date == null)
        .toList();
    _allVideos = [...videosWithDates, ...videosWithoutDates];
    _fetchedThisSession = true;

    // Latest + "by date" derive from the same fetch — no second network call.
    final availableVideos = _allVideos
        .where((video) => video.isAvailable)
        .toList();
    _latestVideo = availableVideos.isNotEmpty ? availableVideos.first : null;
    // Distinct episodes only: some were published twice with a "| Class NN"
    // tail, and "Recent videos" should not show the same one twice.
    _videosByDate = VideoModel.distinctEpisodes(
      availableVideos.where((video) => video.id != _latestVideo?.id),
    ).take(6).toList();

    await StorageService.cacheVideos(_allVideos);
    debugPrint('🎬 [ALL VIDEOS] Total: ${_allVideos.length}');
  }

  // Load videos from the local (1-hour) cache before the network responds.
  Future<void> _loadFromCache() async {
    try {
      if (await StorageService.isCacheFresh()) {
        final cachedVideos = await StorageService.getCachedVideos();
        if (cachedVideos.isNotEmpty) {
          _allVideos = cachedVideos;

          final availableVideos = cachedVideos
              .where((video) => video.isAvailable)
              .toList();
          _latestVideo = availableVideos.isNotEmpty
              ? availableVideos.first
              : null;
          _videosByDate = VideoModel.distinctEpisodes(
            availableVideos.where((video) => video.id != _latestVideo?.id),
          ).take(6).toList();

          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading from cache: $e');
    }
  }

  // Explicit refresh (pull-to-refresh). The only other place allowed to hit
  // the network for the video list besides the first [initialize] (M12).
  Future<void> refresh() async {
    await _setLoadingState(VideoLoadingState.loading);

    try {
      await _fetchAllVideos();
      await loadProgress();
      await _setLoadingState(VideoLoadingState.loaded);
    } catch (e) {
      await _handleError('Failed to refresh videos: $e');
    }
  }

  /// Applies a fresh [VideoProgressStatus] (e.g. the response of a heartbeat
  /// POST) directly into the in-memory map so "Jump back in" and progress
  /// bars update immediately — no app restart required (fixes M13).
  void applyProgress(VideoProgressStatus status) {
    if (status.videoId.isEmpty) return;
    _progressByVideo = {..._progressByVideo, status.videoId: status};
    notifyListeners();
  }

  // Set currently playing video
  void setCurrentlyPlaying(VideoModel? video) {
    _currentlyPlaying = video;
    notifyListeners();
  }

  // Get video by ID
  VideoModel? getVideoById(String id) {
    try {
      return _allVideos.firstWhere((video) => video.id.toString() == id);
    } catch (_) {
      return null;
    }
  }

  /// Episodes with server-side progress (for "Continue watching" sections),
  /// newest activity first.
  List<VideoModel> getVideosWithProgress() {
    final withProgress = _allVideos.where((video) {
      final status = _progressByVideo[video.id];
      return status != null && status.status != 'not-started';
    }).toList();
    withProgress.sort((a, b) {
      final aTime = _progressByVideo[a.id]?.lastViewedAt;
      final bTime = _progressByVideo[b.id]?.lastViewedAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return withProgress;
  }

  // Private helper methods
  Future<void> _setLoadingState(VideoLoadingState state) async {
    _loadingState = state;
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> _handleError(String message) async {
    _loadingState = VideoLoadingState.error;
    _errorMessage = message;
    debugPrint('VideoProvider Error: $message');
    notifyListeners();
  }

  // Search videos (includes all videos - both available and upcoming)
  void searchVideos(String query) {
    _searchQuery = query.trim().toLowerCase();

    if (_searchQuery.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }

    _searchResults = _allVideos.where((video) {
      final titleMatch = video.displayTitle.toLowerCase().contains(
        _searchQuery,
      );
      final captionMatch = video.caption.toLowerCase().contains(_searchQuery);
      return titleMatch || captionMatch;
    }).toList();

    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _searchResults.clear();
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _latestVideo = null;
    _videosByDate.clear();
    _allVideos.clear();
    _searchResults.clear();
    _searchQuery = '';
    _currentlyPlaying = null;
    _loadingState = VideoLoadingState.idle;
    _errorMessage = '';
    _fetchedThisSession = false;
    _progressByVideo = {};
    notifyListeners();
  }
}
