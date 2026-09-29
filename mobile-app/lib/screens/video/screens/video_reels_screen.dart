import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../services/video_progress_service.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../bookmark/provider/bookmark_provider.dart';
import '../model/video_model.dart';
import '../provider/video_provider.dart';
import '../widgets/video_details_sheet.dart';
import '../widgets/learn_note_sheet.dart';
import 'video_player_screen.dart';
import 'video_questions_screen.dart';

/// Full-screen, Reels-style feed: one video per page, swipe up for the next.
///
/// Every page keeps the same watch accounting as the single-video player, so
/// finishing an episode here still marks it complete and offers its questions.
class VideoReelsScreen extends StatefulWidget {
  final List<VideoModel> videos;
  final int initialIndex;

  const VideoReelsScreen({
    super.key,
    required this.videos,
    this.initialIndex = 0,
  });

  /// Opens the feed at [initialIndex], clamped to the list. Upcoming
  /// episodes are dropped first (M15) — a swipe must never reach an
  /// unplayable, empty-URL video.
  static Future<void> open(
    BuildContext context,
    List<VideoModel> videos, {
    int initialIndex = 0,
  }) {
    final playable = <VideoModel>[];
    var adjustedIndex = 0;
    for (var i = 0; i < videos.length; i++) {
      if (videos[i].isUpcoming) continue;
      if (i == initialIndex) adjustedIndex = playable.length;
      playable.add(videos[i]);
    }
    if (playable.isEmpty) return Future<void>.value();

    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoReelsScreen(
          videos: playable,
          initialIndex: adjustedIndex.clamp(0, playable.length - 1),
        ),
      ),
    );
  }

  @override
  State<VideoReelsScreen> createState() => _VideoReelsScreenState();
}

/// Per-video playback and watch state, created lazily as pages are reached.
class _ReelState {
  YoutubePlayerController? youtube;
  vp.VideoPlayerController? direct;
  ChewieController? chewie;
  WebViewController? web;
  VideoProgressStatus? progress;
  bool ready = false;
  Timer? directTicker;

  int lastPosition = 0;
  int pendingWatched = 0;
  int lastHeartbeatAt = -1;
  bool askedQuestions = false;

  void disposeAll() {
    directTicker?.cancel();
    chewie?.dispose();
    direct?.dispose();
    youtube?.dispose();
  }
}

class _VideoReelsScreenState extends State<VideoReelsScreen> {
  late final PageController _pageController;
  late int _index;

  final Map<int, _ReelState> _states = {};
  final Map<int, VoidCallback> _listeners = {};

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _activate(_index);
    });
  }

  @override
  void dispose() {
    final state = _states[_index];
    if (state != null && state.ready) {
      final position =
          state.youtube?.value.position.inSeconds ??
          state.direct?.value.position.inSeconds;
      if (position != null) {
        unawaited(_sendHeartbeat(_index, position));
      }
    }

    for (final entry in _states.entries) {
      final listener = _listeners[entry.key];
      if (listener != null) entry.value.youtube?.removeListener(listener);
      entry.value.disposeAll();
    }
    _listeners.clear();
    _states.clear();
    _pageController.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  // ---------------------------------------------------------------- lifecycle

  /// Server-known resume position for [video] — seeded once per session via
  /// `VideoProvider.loadProgress()`, never the on-device cache (M14).
  int _startAtFor(VideoModel video) {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    final status = videoProvider.progressFor(video.id);
    if (status != null) return status.positionSeconds;
    return 0;
  }

  _ReelState _stateFor(int index) {
    return _states.putIfAbsent(index, () {
      final video = widget.videos[index];
      final state = _ReelState();

      if (video.isLiveVideo) {
        state.web = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(AppColors.black)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (_) {
                if (mounted) setState(() => state.ready = true);
              },
              onWebResourceError: (error) {
                debugPrint('Reels WebView error: ${error.description}');
              },
            ),
          )
          ..loadRequest(Uri.parse(_liveEmbedUrl(video.videoUrl)));
        unawaited(_loadProgress(index));
      } else if (video.isYouTubeVideo) {
        final videoId = YoutubePlayer.convertUrlToId(video.videoUrl);
        if (videoId != null) {
          state.youtube = YoutubePlayerController(
            initialVideoId: videoId,
            flags: YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              enableCaption: true,
              captionLanguage: 'ml',
              startAt: _startAtFor(video),
            ),
          );

          void listener() => _onYoutubeTick(index);
          _listeners[index] = listener;
          state.youtube!.addListener(listener);
        }
        unawaited(_loadProgress(index));
      } else if (video.videoUrl.isNotEmpty) {
        unawaited(_initializeDirect(index, state, video));
        unawaited(_loadProgress(index));
      }

      return state;
    });
  }

  /// Non-YouTube (CDN-hosted) videos: `video_player` + `chewie`, in both the
  /// reels view and the full player (M16).
  Future<void> _initializeDirect(
    int index,
    _ReelState state,
    VideoModel video,
  ) async {
    final controller = vp.VideoPlayerController.networkUrl(
      Uri.parse(video.videoUrl),
    );
    state.direct = controller;
    try {
      await controller.initialize().timeout(const Duration(seconds: 12));
      final startAt = _startAtFor(video);
      if (startAt > 0) {
        await controller.seekTo(Duration(seconds: startAt));
        state.lastPosition = startAt;
      }
      if (!mounted) return;
      state.chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: _states[_index] == state,
        looping: false,
        aspectRatio: video.playerAspectRatio,
        showControls: true,
      );
      setState(() => state.ready = true);
      state.directTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        _onDirectTick(index);
      });
    } catch (e) {
      debugPrint('Reels direct player init failed: $e');
    }
  }

  void _onDirectTick(int index) {
    final state = _states[index];
    final controller = state?.direct;
    if (state == null ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }
    if (!controller.value.isPlaying) return;

    final position = controller.value.position.inSeconds;
    final delta = position - state.lastPosition;
    if (delta > 0 && delta <= 5) state.pendingWatched += delta;
    state.lastPosition = position;

    if (position > 0 && position % 5 == 0) {
      unawaited(_sendHeartbeat(index, position));
    }

    if (controller.value.position >= controller.value.duration &&
        controller.value.duration > Duration.zero) {
      unawaited(_sendHeartbeat(index, controller.value.duration.inSeconds));
    }
  }

  void _onYoutubeTick(int index) {
    final state = _states[index];
    if (state == null) return;

    final controller = state.youtube;
    if (controller == null || !state.ready) return;

    final position = controller.value.position.inSeconds;
    final delta = position - state.lastPosition;
    if (delta > 0 && delta <= 5) state.pendingWatched += delta;
    state.lastPosition = position;

    if (position > 0 && position % 5 == 0) {
      unawaited(_sendHeartbeat(index, position));
    }
  }

  void _activate(int index) {
    for (final entry in _states.entries) {
      final isCurrent = entry.key == index;
      final youtube = entry.value.youtube;
      if (youtube != null) {
        if (isCurrent) {
          youtube.play();
        } else if (youtube.value.isPlaying) {
          youtube.pause();
        }
      }
      final direct = entry.value.direct;
      if (direct != null && direct.value.isInitialized) {
        if (isCurrent) {
          direct.play();
        } else if (direct.value.isPlaying) {
          direct.pause();
        }
      }
    }
  }

  void _onPageChanged(int index) {
    final previous = _index;
    setState(() => _index = index);

    final previousState = _states[previous];
    previousState?.youtube?.pause();
    if (previousState?.direct?.value.isPlaying == true) {
      previousState!.direct!.pause();
    }

    _activate(index);
    unawaited(_loadProgress(index));
  }

  // ------------------------------------------------------------- watch state

  Future<void> _loadProgress(int index) async {
    final state = _stateFor(index);
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    final cached = videoProvider.progressFor(widget.videos[index].id);
    if (cached != null && mounted) {
      setState(() => state.progress = cached);
    }
  }

  Future<void> _sendHeartbeat(int index, int positionInSeconds) async {
    final video = widget.videos[index];
    final state = _stateFor(index);
    if (positionInSeconds == state.lastHeartbeatAt) return;
    state.lastHeartbeatAt = positionInSeconds;

    final duration =
        state.youtube?.value.metaData.duration.inSeconds ??
        state.direct?.value.duration.inSeconds;
    final watchedDelta = state.pendingWatched;
    state.pendingWatched = 0;

    final status = await VideoProgressService.heartbeat(
      videoId: video.id,
      position: positionInSeconds,
      duration: duration,
      watchedDelta: watchedDelta,
    );

    if (!mounted || status == null) return;
    setState(() => state.progress = status);

    if (!mounted) return;
    Provider.of<VideoProvider>(context, listen: false).applyProgress(status);

    if (status.completed) await _afterCompletion(index, status);
  }

  Future<void> _afterCompletion(int index, VideoProgressStatus status) async {
    final state = _stateFor(index);
    if (state.askedQuestions || !status.hasQuestions || !mounted) return;
    state.askedQuestions = true;

    final video = widget.videos[index];

    final start = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: AppColors.success),
                SizedBox(width: 8),
                Text(
                  'Video completed',
                  style: AppFonts.bold(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'You finished "${video.displayTitle}". '
              'Answer ${status.questionCount} question'
              '${status.questionCount == 1 ? '' : 's'} about it.',
              style: AppFonts.regular(color: AppColors.textMuted, height: 1.35),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Answer ${status.questionCount} question'
                  '${status.questionCount == 1 ? '' : 's'}',
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Later',
                style: AppFonts.medium(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );

    if (start != true || !mounted) return;
    await VideoQuestionsScreen.open(context, video);
  }

  void _openPractice(int index) {
    final state = _stateFor(index);
    if (state.progress?.completed != true) return;
    VideoQuestionsScreen.open(context, widget.videos[index]);
  }

  Future<void> _toggleBookmark(VideoModel video) async {
    final bookmarkProvider = Provider.of<BookmarkProvider>(
      context,
      listen: false,
    );
    final success = await bookmarkProvider.toggleBookmark(video);
    if (!success || !mounted) return;

    final isBookmarked = bookmarkProvider.isBookmarkedSync(video.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isBookmarked ? 'Added to bookmarks' : 'Removed from bookmarks',
          style: AppFonts.regular(color: AppColors.onPrimary),
        ),
        backgroundColor: AppColors.textPrimary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Opens the full player for [video], pausing this reel's own player first
  /// so two players/audio tracks never run at once (M17).
  void _openFullPlayer(int index, VideoModel video) {
    final state = _stateFor(index);
    state.youtube?.pause();
    if (state.direct?.value.isPlaying == true) {
      state.direct!.pause();
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)));
  }

  // --------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.videos.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) => _buildPage(index),
      ),
    );
  }

  Widget _buildPage(int index) {
    final video = widget.videos[index];
    final state = _stateFor(index);

    return Stack(
      fit: StackFit.expand,
      children: [
        _videoLayer(index, video, state),

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              height: 320,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.transparent, AppColors.scrimStrong],
                ),
              ),
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _circleButton(
                  Icons.arrow_back,
                  () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                if (video.isLiveVideo)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'LIVE',
                      style: AppFonts.bold(
                        color: AppColors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                if (state.progress?.completed == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppColors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: AppFonts.semiBold(
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        Positioned(
          right: 12,
          bottom: 150,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<BookmarkProvider>(
                  builder: (context, bookmarkProvider, child) {
                    final isBookmarked = bookmarkProvider.isBookmarkedSync(
                      video.id,
                    );
                    return _railButton(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      isBookmarked ? 'Saved' : 'Save',
                      () => _toggleBookmark(video),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _railButton(
                  Icons.info_outline,
                  'Details',
                  () => VideoDetailsSheet.show(context, video),
                ),
                const SizedBox(height: 14),
                _railButton(
                  Icons.fullscreen,
                  'Full',
                  () => _openFullPlayer(index, video),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          left: 20,
          right: 84,
          bottom: 20,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _detailsChip('Learn', 0, video),
                    _detailsChip('Downloads', 1, video),
                    _practiceChip(index, state),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  video.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.bold(
                    color: AppColors.white,
                    fontSize: 17,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if ((video.subjectName ?? '').isNotEmpty)
                      video.subjectName!,
                    if (video.formattedDate.isNotEmpty) video.formattedDate,
                  ].join('  ·  '),
                  style: AppFonts.regular(
                    color: AppColors.white70,
                    fontSize: 12.5,
                  ),
                ),
                if (state.progress != null &&
                    !state.progress!.completed &&
                    state.progress!.percent > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: state.progress!.percent,
                      minHeight: 3,
                      backgroundColor: AppColors.white24,
                      valueColor: const AlwaysStoppedAnimation(AppColors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _videoLayer(int index, VideoModel video, _ReelState state) {
    if (video.isLiveVideo) {
      if (state.web == null) return const SizedBox.shrink();
      return state.ready
          ? WebViewWidget(controller: state.web!)
          : const Center(
              child: CircularProgressIndicator(color: AppColors.white),
            );
    }

    if (video.isYouTubeVideo) {
      final controller = state.youtube;
      if (controller == null) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This video cannot be played here.',
              textAlign: TextAlign.center,
              style: AppFonts.regular(color: AppColors.white70),
            ),
          ),
        );
      }
      return Center(
        child: AspectRatio(
          aspectRatio: video.playerAspectRatio,
          child: YoutubePlayer(
            controller: controller,
            showVideoProgressIndicator: false,
            onReady: () {
              if (!mounted) return;
              setState(() => state.ready = true);
              if (_states[_index] == state) controller.play();
            },
            onEnded: (_) {
              final total = controller.value.metaData.duration.inSeconds;
              unawaited(_sendHeartbeat(index, total));
            },
          ),
        ),
      );
    }

    // Direct (CDN) video: video_player + chewie (M16).
    if (!state.ready || state.chewie == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: video.playerAspectRatio,
        child: Chewie(controller: state.chewie!),
      ),
    );
  }

  String _liveEmbedUrl(String originalUrl) {
    final videoId = RegExp(
      r'live/([a-zA-Z0-9_-]{11})',
    ).firstMatch(originalUrl)?.group(1);
    if (videoId != null) {
      return 'https://www.youtube.com/embed/$videoId?autoplay=1&modestbranding=1&rel=0';
    }
    return originalUrl;
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
      ),
    );
  }

  Widget _railButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _circleButton(icon, onTap),
          Text(
            label,
            style: AppFonts.semiBold(color: AppColors.white, fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Widget _detailsChip(String label, int tab, VideoModel video) {
    final onTap = tab == 0
        ? () => LearnNoteSheet.show(context, video)
        : () => VideoDetailsSheet.show(context, video, initialTab: tab);
    return _chip(label, onTap, enabled: true);
  }

  /// Practice unlocks only once `progress.completed == true` for this video
  /// (M19) — no local heuristic decides this.
  Widget _practiceChip(int index, _ReelState state) {
    final unlocked = state.progress?.completed == true;
    return _chip(
      'Practice',
      unlocked ? () => _openPractice(index) : null,
      enabled: unlocked,
    );
  }

  Widget _chip(String label, VoidCallback? onTap, {bool enabled = true}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: enabled ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppFonts.semiBold(
            color: enabled ? AppColors.white : AppColors.white38,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}
