import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../services/video_progress_service.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/animation/pop_on_change.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../../bookmark/provider/bookmark_provider.dart';
import '../model/video_model.dart';
import '../provider/video_reels_screen_provider.dart';
import '../provider/youtube_playback_toggle.dart';
import '../provider/video_provider.dart';
import '../widgets/video_details_sheet.dart';
import '../widgets/learn_note_sheet.dart';
import '../widgets/video_loading_spinner.dart';
import '../widgets/video_poster.dart';
import '../widgets/video_scrim.dart';
import '../widgets/player_dispose_notifier.dart';
import '../widgets/video_title_block.dart';
import '../widgets/youtube_centre_button.dart';
import '../widgets/youtube_seek_bar.dart';
import '../widgets/youtube_tap_zones.dart';
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
  Timer? directTicker;

  int lastPosition = 0;
  int pendingWatched = 0;
  int lastHeartbeatAt = -1;
  bool askedQuestions = false;

  /// Whether the seek bar was being dragged at the last player update.
  bool dragging = false;

  /// The centre play / pause button's logic, for YouTube reels.
  YoutubePlaybackToggle? playback;

  void disposeAll() {
    playback?.dispose();
    directTicker?.cancel();
    chewie?.dispose();
    direct?.dispose();
    youtube?.dispose();
  }
}

class _VideoReelsScreenState extends State<VideoReelsScreen> {
  late final PageController _pageController;
  late final VideoReelsScreenProvider _reels;

  final Map<int, _ReelState> _states = {};
  final Map<int, VoidCallback> _listeners = {};

  @override
  void initState() {
    super.initState();
    _reels = VideoReelsScreenProvider(initialIndex: widget.initialIndex);
    _pageController = PageController(initialPage: _reels.index);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _activate(_reels.index);
    });
  }

  @override
  void dispose() {
    final state = _states[_reels.index];
    if (state != null && _reels.isReady(_reels.index)) {
      final position =
          state.youtube?.value.position.inSeconds ??
          state.direct?.value.position.inSeconds;
      if (position != null) {
        unawaited(_sendHeartbeat(_reels.index, position));
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
    _reels.dispose();

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
                if (mounted) _reels.markReady(index);
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
              // The reels draw their own tap-to-play and seek bar: the plugin's
              // controls need two taps and sit under the chips and title.
              hideControls: true,
              // Hides YouTube's own title bar, share button, "More videos" and
              // logo, so only the reels' controls are on the video.
              hideYoutubeOverlay: true,
              // The plugin fades its thumbnail over the video whenever it is
              // not playing, so pausing swapped the frame for the poster.
              hideThumbnail: true,
              mute: false,
              enableCaption: true,
              captionLanguage: 'ml',
              startAt: _startAtFor(video),
            ),
          );

          state.playback = YoutubePlaybackToggle(state.youtube!);

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
        autoPlay: _states[_reels.index] == state,
        looping: false,
        aspectRatio: video.playerAspectRatio,
        showControls: true,
      );
      _reels.markReady(index);
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

  /// A reel's player widget is dropped when it scrolls away, and its web view
  /// goes with it, but the controller lives on still pointing at that dead web
  /// view and still saying it is ready. A later play or pause (swiping back to
  /// the reel calls one at once) would then reach a web view that no longer
  /// exists. Resetting marks the controller not ready, so those calls wait
  /// until the new web view reports ready; the thumbnail covers the player
  /// again meanwhile.
  void _onPlayerGone(int index, YoutubePlayerController controller) {
    // Not during the unmount itself: resetting notifies listeners.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // If the whole screen is closing, the controller goes with it.
      if (!mounted) return;
      controller.reset();
      _reels.setStarted(index, false);
    });
  }

  void _onYoutubeTick(int index) {
    final state = _states[index];
    if (state == null) return;

    final controller = state.youtube;
    if (controller == null || !_reels.isReady(index)) return;

    // Lets the thumbnail cover the player until the first frame plays, and
    // again once the video ends (hiding YouTube's own end screen).
    final playerState = controller.value.playerState;
    if (playerState == PlayerState.playing) _reels.setStarted(index, true);
    if (playerState == PlayerState.ended) _reels.setStarted(index, false);

    // Keeps the controls open while the seek bar is dragged, and for the usual
    // few seconds after the finger lifts, so the bar never vanishes on release.
    final dragging = controller.value.isDragging;
    if (dragging != state.dragging) {
      state.dragging = dragging;
      _reels.showControls(index, canHide: () => !controller.value.isDragging);
    }

    final position = controller.value.position.inSeconds;
    final delta = position - state.lastPosition;
    if (delta > 0 && delta <= 5) state.pendingWatched += delta;
    state.lastPosition = position;

    if (position > 0 && position % 5 == 0) {
      unawaited(_sendHeartbeat(index, position));
    }
  }

  /// A tap anywhere on the screen shows the controls, or hides them if they
  /// are already open. It never pauses.
  void _onTapVideo(int index, YoutubePlayerController controller) {
    _reels.toggleControls(index, canHide: () => !controller.value.isDragging);
  }

  /// A tap on the centre square plays or pauses. It leaves the seek bar alone:
  /// the bar and the centre button are independent.
  void _onTapCentre(_ReelState state) => state.playback?.toggle();

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
    final previous = _reels.index;
    _reels.setIndex(index);

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
    // Called while a page is being built (via _stateFor); let that build
    // finish before notifying listeners.
    await Future<void>.value();
    if (!mounted) return;
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    final cached = videoProvider.progressFor(widget.videos[index].id);
    if (cached != null && mounted) {
      _reels.setProgress(index, cached);
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
    _reels.setProgress(index, status);

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
                Icon(LucideIcons.badgeCheck, color: AppColors.success),
                SizedBox(width: 8),
                Text(
                  'Video Completed',
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
                  'Answer ${status.questionCount} Question'
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
    if (_reels.progressFor(index)?.completed != true) return;
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
    AppSnackBar.show(
      context,
      message: isBookmarked
          ? 'Saved to your bookmarks'
          : 'Removed from your bookmarks',
      color: AppColors.success,
      duration: const Duration(seconds: 2),
    );
  }

  // --------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _reels,
      child: Consumer<VideoReelsScreenProvider>(
        builder: (_, reels, __) => _buildFeed(reels),
      ),
    );
  }

  Widget _buildFeed(VideoReelsScreenProvider reels) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.videos.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) => _buildPage(reels, index),
      ),
    );
  }

  Widget _buildPage(VideoReelsScreenProvider reels, int index) {
    final video = widget.videos[index];
    final state = _stateFor(index);
    final progress = reels.progressFor(index);
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Stack(
      fit: StackFit.expand,
      children: [
        _videoLayer(reels, index, video, state),

        // The whole screen reveals or hides the controls when tapped; only the
        // centre square (where the play / pause button is) plays or pauses.
        if (state.youtube != null)
          YoutubeTapZones(
            onTapVideo: () => _onTapVideo(index, state.youtube!),
            onTapCentre: () => _onTapCentre(state),
          ),

        if (landscape)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: VideoScrim(height: 120, fromTop: true),
          ),

        // Skipped in landscape: nothing sits at the bottom there, and the fade
        // would dim the player's own seek bar and buttons underneath it.
        if (!landscape)
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
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _circleButton(
                    LucideIcons.arrowLeft,
                    () => Navigator.of(context).pop(),
                  ),
                  if (landscape)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: VideoTitleBlock(video: video),
                      ),
                    )
                  else
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
                  if (progress?.completed == true)
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
                            LucideIcons.circleCheck,
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
                  // Landscape has no room beside the title at the bottom, so Save
                  // and Details join the top bar as icon-only buttons.
                  if (landscape) ...[
                    const SizedBox(width: 4),
                    _saveButton(video, landscape: true),
                    _detailsButton(video, landscape: true),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Chips and title on the left with Save and Details stacked in a column
        // on their right, like an Instagram reel (portrait only), with the seek
        // bar under them, all in one column so the bar can never overlap the
        // text.
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!landscape)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
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
                                _practiceChip(reels, index),
                              ],
                            ),
                            const SizedBox(height: 12),
                            VideoTitleBlock(video: video),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _saveButton(video, landscape: false),
                          const SizedBox(height: 8),
                          _detailsButton(video, landscape: false),
                        ],
                      ),
                    ],
                  ),
                if (state.youtube != null) ...[
                  const SizedBox(height: 8),
                  YoutubeSeekBar(
                    controller: state.youtube!,
                    controlsShown: reels.areControlsShown(index),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _videoLayer(
    VideoReelsScreenProvider reels,
    int index,
    VideoModel video,
    _ReelState state,
  ) {
    if (video.isLiveVideo) {
      if (state.web == null) return const SizedBox.shrink();
      return reels.isReady(index)
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
      // The poster sits on top until the player is ready, covering the
      // plugin's own spinner (its `bufferIndicator` option is not wired up).
      return Center(
        child: AspectRatio(
          aspectRatio: video.playerAspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PlayerDisposeNotifier(
                onDispose: () => _onPlayerGone(index, controller),
                child: YoutubePlayer(
                  controller: controller,
                  showVideoProgressIndicator: false,
                  onReady: () {
                    if (!mounted) return;
                    _reels.markReady(index);
                    if (_states[_reels.index] == state) controller.play();
                  },
                  onEnded: (_) {
                    final total = controller.value.metaData.duration.inSeconds;
                    unawaited(_sendHeartbeat(index, total));
                  },
                ),
              ),
              VideoPoster(
                thumbnailUrl: video.thumbnailUrl,
                visible: !reels.isStarted(index),
              ),
              YoutubeCentreButton(
                controller: controller,
                started: reels.isStarted(index),
                controlsShown: reels.areControlsShown(index),
              ),
            ],
          ),
        ),
      );
    }

    // Direct (CDN) video: video_player + chewie (M16).
    if (!reels.isReady(index) || state.chewie == null) {
      return Center(
        child: AspectRatio(
          aspectRatio: video.playerAspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoPoster(thumbnailUrl: video.thumbnailUrl),
              const VideoLoadingSpinner(loading: true),
            ],
          ),
        ),
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

  /// [pressable] is off when a parent already squishes the whole button.
  Widget _circleButton(
    IconData icon,
    VoidCallback onTap, {
    bool pressable = true,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: PressableScale(
        enabled: pressable,
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
      ),
    );
  }

  /// Bookmark toggle: a labelled button beside the title in portrait, an
  /// icon-only button (with a tooltip) in the landscape top bar.
  Widget _saveButton(VideoModel video, {required bool landscape}) {
    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, child) {
        final isBookmarked = bookmarkProvider.isBookmarkedSync(video.id);
        final icon = isBookmarked
            ? LucideIcons.bookmarkCheck
            : LucideIcons.bookmark;
        final label = isBookmarked ? 'Saved' : 'Save';
        void onTap() => _toggleBookmark(video);
        return PopOnChange(
          active: isBookmarked,
          peak: 1.2,
          child: landscape
              ? Tooltip(message: label, child: _circleButton(icon, onTap))
              : _railButton(icon, label, onTap),
        );
      },
    );
  }

  /// Opens the episode details sheet; same placement rules as [_saveButton].
  Widget _detailsButton(VideoModel video, {required bool landscape}) {
    void onTap() => VideoDetailsSheet.show(context, video);
    return landscape
        ? Tooltip(
            message: 'Details',
            child: _circleButton(LucideIcons.info, onTap),
          )
        : _railButton(LucideIcons.info, 'Details', onTap);
  }

  Widget _railButton(IconData icon, String label, VoidCallback onTap) {
    return PressableScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _circleButton(icon, onTap, pressable: false),
            Text(
              label,
              style: AppFonts.semiBold(color: AppColors.white, fontSize: 10.5),
            ),
          ],
        ),
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
  Widget _practiceChip(VideoReelsScreenProvider reels, int index) {
    final unlocked = reels.progressFor(index)?.completed == true;
    return PopOnChange(
      active: unlocked,
      peak: 1.15,
      child: _chip(
        'Practice',
        unlocked ? () => _openPractice(index) : null,
        enabled: unlocked,
      ),
    );
  }

  Widget _chip(String label, VoidCallback? onTap, {bool enabled = true}) {
    return PressableScale(
      enabled: onTap != null,
      child: InkWell(
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
      ),
    );
  }
}
