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
import '../../../widgets/common/app_snack_bar.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../bookmark/provider/bookmark_provider.dart';
import '../model/video_model.dart';
import '../provider/video_provider.dart';
import '../widgets/learn_note_sheet.dart';
import '../widgets/video_details_sheet.dart';
import 'video_questions_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _youtubeController;
  vp.VideoPlayerController? _directController;
  ChewieController? _chewieController;
  WebViewController? _webViewController;
  bool _isPlayerReady = false;
  bool _isFullScreen = false;
  bool _isLiveStream = false;
  bool _isDirect = false;

  // Server-side watch state for this video.
  VideoProgressStatus? _progress;
  int _lastKnownPosition = 0;
  int _pendingWatchedSeconds = 0;
  int _lastHeartbeatAt = -1;
  bool _askedQuestions = false;
  Timer? _directTicker;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  /// Server-known resume position for this video, seeded once per session
  /// via `VideoProvider.loadProgress()` — not the on-device cache (M14).
  int get _startAt {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    return videoProvider.progressFor(widget.video.id)?.positionSeconds ?? 0;
  }

  void _initializePlayer() {
    _isLiveStream = widget.video.isLiveVideo;

    if (_isLiveStream) {
      _initializeWebView();
      return;
    }

    if (widget.video.isYouTubeVideo) {
      final videoId = YoutubePlayer.convertUrlToId(widget.video.videoUrl);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: true,
            captionLanguage: 'ml',
            startAt: _startAt,
          ),
        );
        _youtubeController?.addListener(_onYoutubeTick);
      }
      return;
    }

    if (widget.video.videoUrl.isNotEmpty) {
      _isDirect = true;
      _initializeDirectPlayer();
    }
  }

  /// Non-YouTube (CDN-hosted) videos: `video_player` + `chewie`, replacing the
  /// old "open in browser" fallback (M16).
  Future<void> _initializeDirectPlayer() async {
    final controller = vp.VideoPlayerController.networkUrl(
      Uri.parse(widget.video.videoUrl),
    );
    _directController = controller;
    try {
      await controller.initialize().timeout(const Duration(seconds: 12));
      if (_startAt > 0) {
        await controller.seekTo(Duration(seconds: _startAt));
        _lastKnownPosition = _startAt;
      }
      if (!mounted) return;
      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        aspectRatio: widget.video.playerAspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          bufferedColor: AppColors.textMuted.withValues(alpha: 0.3),
          backgroundColor: AppColors.surfaceAlt,
        ),
      );
      setState(() => _isPlayerReady = true);
      _directTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        _onDirectTick();
      });
    } catch (e) {
      debugPrint('Direct video player init failed: $e');
    }
  }

  void _onDirectTick() {
    final controller = _directController;
    if (controller == null || !controller.value.isInitialized || !mounted) {
      return;
    }
    final position = controller.value.position.inSeconds;
    if (!controller.value.isPlaying) return;

    final delta = position - _lastKnownPosition;
    if (delta > 0 && delta <= 5) _pendingWatchedSeconds += delta;
    _lastKnownPosition = position;

    if (position > 0 && position % 5 == 0) {
      _saveProgress(position);
    }

    if (controller.value.position >= controller.value.duration &&
        controller.value.duration > Duration.zero) {
      unawaited(_sendHeartbeat(controller.value.duration.inSeconds));
    }
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isPlayerReady = true;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(_getEmbedUrl(widget.video.videoUrl)));
  }

  String _getEmbedUrl(String originalUrl) {
    if (originalUrl.contains('youtube.com/live/')) {
      final videoId = RegExp(
        r'live/([a-zA-Z0-9_-]{11})',
      ).firstMatch(originalUrl)?.group(1);
      if (videoId != null) {
        return 'https://www.youtube.com/embed/$videoId?autoplay=0&modestbranding=1&rel=0';
      }
    }
    return originalUrl;
  }

  void _onYoutubeTick() {
    if (_isPlayerReady && mounted && _youtubeController != null) {
      final position = _youtubeController!.value.position.inSeconds;

      // Only forward playback counts. A seek makes delta jump far beyond the
      // heartbeat window and is ignored, so scrubbing to the end does not count
      // as watching — the server decides completion from watched seconds.
      final delta = position - _lastKnownPosition;
      if (delta > 0 && delta <= 5) {
        _pendingWatchedSeconds += delta;
      }
      _lastKnownPosition = position;

      if (position > 0 && position % 5 == 0) {
        _saveProgress(position);
      }
    }
  }

  void _saveProgress(int positionInSeconds) {
    if (positionInSeconds == _lastHeartbeatAt) return;
    _lastHeartbeatAt = positionInSeconds;
    unawaited(_sendHeartbeat(positionInSeconds));
  }

  Future<void> _sendHeartbeat(int positionInSeconds) async {
    final duration = _isDirect
        ? _directController?.value.duration.inSeconds
        : _youtubeController?.value.metaData.duration.inSeconds;
    final watchedDelta = _pendingWatchedSeconds;
    _pendingWatchedSeconds = 0;

    final status = await VideoProgressService.heartbeat(
      videoId: widget.video.id,
      position: positionInSeconds,
      duration: duration,
      watchedDelta: watchedDelta,
    );

    if (!mounted || status == null) return;
    setState(() => _progress = status);

    // Apply immediately so "Jump back in" / progress bars elsewhere update
    // without waiting for an app restart (fixes M13).
    Provider.of<VideoProvider>(context, listen: false).applyProgress(status);

    if (status.completed) {
      await _afterCompletion(status);
    }
  }

  /// Once the video is genuinely finished, ask the questions attached to it.
  Future<void> _afterCompletion(VideoProgressStatus status) async {
    if (_askedQuestions || !status.hasQuestions || !mounted) return;
    _askedQuestions = true;

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
              'You finished "${widget.video.displayTitle}". '
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
    await VideoQuestionsScreen.open(context, widget.video);
  }

  void _openPractice() {
    if (_progress?.completed != true) return;
    VideoQuestionsScreen.open(context, widget.video);
  }

  void _toggleBookmark() async {
    final bookmarkProvider = Provider.of<BookmarkProvider>(
      context,
      listen: false,
    );
    final success = await bookmarkProvider.toggleBookmark(widget.video);

    if (success && mounted) {
      final isBookmarked = bookmarkProvider.isBookmarkedSync(widget.video.id);
      AppSnackBar.show(
        context,
        message: isBookmarked
            ? 'Saved to your bookmarks'
            : 'Removed from your bookmarks',
        color: AppColors.success,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  void dispose() {
    // Save final progress before disposing.
    if (_isPlayerReady && !_isLiveStream) {
      if (_youtubeController != null) {
        _saveProgress(_youtubeController!.value.position.inSeconds);
      } else if (_directController?.value.isInitialized == true) {
        _saveProgress(_directController!.value.position.inSeconds);
      }
    }

    _youtubeController?.removeListener(_onYoutubeTick);
    _youtubeController?.dispose();
    _directTicker?.cancel();
    _chewieController?.dispose();
    _directController?.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLiveStream && _webViewController != null) {
      return _buildLiveStreamPlayer();
    }

    if (_isDirect) {
      return _buildDirectPlayerScreen();
    }

    final videoId = YoutubePlayer.convertUrlToId(widget.video.videoUrl);
    if (videoId == null || _youtubeController == null) {
      return _buildUnsupportedScreen();
    }

    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        setState(() {
          _isFullScreen = false;
        });
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      },
      onEnterFullScreen: () {
        setState(() {
          _isFullScreen = true;
        });
      },
      player: YoutubePlayer(
        controller: _youtubeController!,
        aspectRatio: widget.video.playerAspectRatio,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primary,
        progressColors: ProgressBarColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          bufferedColor: AppColors.textMuted.withValues(alpha: 0.3),
          backgroundColor: AppColors.surfaceAlt,
        ),
        onReady: () {
          setState(() {
            _isPlayerReady = true;
          });
        },
        onEnded: (metaData) {
          if (_youtubeController != null) {
            final total = _youtubeController!.value.metaData.duration.inSeconds;
            unawaited(_sendHeartbeat(total));
          }
        },
      ),
      builder: (context, player) => _buildReelsStyleScaffold(player),
    );
  }

  Widget _buildDirectPlayerScreen() {
    if (!_isPlayerReady || _chewieController == null) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return _buildReelsStyleScaffold(
      AspectRatio(
        aspectRatio: widget.video.playerAspectRatio,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }

  /// The Reels-style stage shared by the YouTube and direct-URL players: the
  /// video centred on a black background with the overlay controls on top.
  Widget _buildReelsStyleScaffold(Widget player) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: widget.video.playerAspectRatio,
              child: player,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 260,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.transparent, AppColors.scrim],
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
                  if (_progress?.completed == true)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
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
                  Consumer<BookmarkProvider>(
                    builder: (context, bookmarkProvider, child) {
                      final isBookmarked = bookmarkProvider.isBookmarkedSync(
                        widget.video.id,
                      );
                      return _circleButton(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        _toggleBookmark,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
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
                  Row(
                    children: [
                      _detailsChip('Learn', 0),
                      const SizedBox(width: 8),
                      _detailsChip('Downloads', 1),
                      const SizedBox(width: 8),
                      _practiceChip(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.video.displayTitle,
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
                      if (widget.video.subjectName != null &&
                          widget.video.subjectName!.isNotEmpty)
                        widget.video.subjectName!,
                      if (widget.video.formattedDate.isNotEmpty)
                        widget.video.formattedDate,
                    ].join('  ·  '),
                    style: AppFonts.regular(
                      color: AppColors.white70,
                      fontSize: 12.5,
                    ),
                  ),
                  if (_progress != null &&
                      !_progress!.completed &&
                      _progress!.percent > 0) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: _progress!.percent,
                        minHeight: 3,
                        backgroundColor: AppColors.white24,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Chip that opens one tab of the episode details sheet.
  Widget _detailsChip(String label, int tab) {
    final onTap = tab == 0
        ? () => LearnNoteSheet.show(context, widget.video)
        : () => VideoDetailsSheet.show(context, widget.video, initialTab: tab);

    return _chip(label, onTap);
  }

  /// The Practice chip is disabled until the video is marked complete on the
  /// server (M19) — no local heuristic decides this, only `_progress`.
  Widget _practiceChip() {
    final unlocked = _progress?.completed == true;
    return _chip(
      'Practice',
      unlocked ? _openPractice : null,
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

  Widget _buildLiveStreamPlayer() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _isFullScreen
          ? null
          : CommonAppBar(
              title: widget.video.displayTitle,
              actions: [
                Consumer<BookmarkProvider>(
                  builder: (context, bookmarkProvider, child) {
                    final isBookmarked = bookmarkProvider.isBookmarkedSync(
                      widget.video.id,
                    );
                    return IconButton(
                      onPressed: _toggleBookmark,
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                      tooltip: isBookmarked
                          ? 'Remove bookmark'
                          : 'Add bookmark',
                    );
                  },
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isFullScreen = !_isFullScreen;
                    });
                    SystemChrome.setPreferredOrientations(
                      _isFullScreen
                          ? [
                              DeviceOrientation.landscapeLeft,
                              DeviceOrientation.landscapeRight,
                            ]
                          : [
                              DeviceOrientation.portraitUp,
                              DeviceOrientation.portraitDown,
                            ],
                    );
                  },
                  icon: Icon(
                    _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
      body: Column(
        children: [
          Expanded(
            flex: _isFullScreen ? 1 : 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(color: AppColors.black),
              child: _isPlayerReady
                  ? WebViewWidget(controller: _webViewController!)
                  : const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
          if (!_isFullScreen)
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: AppFonts.bold(
                              color: AppColors.onPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    Text(
                      widget.video.displayTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (widget.video.caption.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.paddingMedium),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.paddingMedium),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                        child: Text(
                          widget.video.caption,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(title: widget.video.displayTitle),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.textMuted),
              const SizedBox(height: AppTheme.paddingMedium),
              Text(
                'This video cannot be played right now.',
                textAlign: TextAlign.center,
                style: AppFonts.regular(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppTheme.paddingLarge),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
