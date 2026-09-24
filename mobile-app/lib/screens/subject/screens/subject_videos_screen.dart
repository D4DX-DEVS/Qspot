import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/subject_model.dart';
import '../../video/model/video_model.dart';
import '../../video/provider/video_provider.dart';
import '../../../services/api_client.dart';
import '../../video/widgets/video_card.dart';
import '../widgets/chapter_guide_sheet.dart';
import '../../../themes/app_theme.dart';
import '../../video/screens/video_reels_screen.dart';

class SubjectVideosScreen extends StatefulWidget {
  final SubjectModel subject;

  const SubjectVideosScreen({super.key, required this.subject});

  @override
  State<SubjectVideosScreen> createState() => _SubjectVideosScreenState();
}

class _SubjectVideosScreenState extends State<SubjectVideosScreen> {
  List<VideoModel> _videos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSubjectVideos();
    _maybeShowChapterGuide();
  }

  /// The first time a chapter is opened on this device, explain what is inside
  /// it before the student starts watching.
  Future<void> _maybeShowChapterGuide() async {
    final subject = widget.subject;
    final shouldShow = await ChapterGuideSheet.shouldShow(subject.id);
    if (!shouldShow || !mounted) return;

    await ChapterGuideSheet.markSeen(subject.id);
    if (!mounted) return;

    // Wait for the first frame so the sheet has something to sit on top of.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ChapterGuideSheet.show(context, subject);
    });
  }

  // Fetches only this subject's videos server-side (`?subject=<id>`) instead
  // of downloading the full catalogue and filtering client-side (M12).
  Future<void> _loadSubjectVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final body = await ApiClient.get(
        '/api/videos',
        query: {'subject': widget.subject.id},
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

      debugPrint(
        '📚 [SUBJECT VIDEOS] Loaded ${videos.length} for ${widget.subject.id}',
      );

      if (!mounted) return;
      setState(() {
        _videos = videos;
        _isLoading = false;
      });

      // Watch status for these videos comes from the account (fetched once
      // per session by VideoProvider), not local storage.
      await Provider.of<VideoProvider>(context, listen: false).loadProgress();
    } catch (e) {
      debugPrint('📚 [SUBJECT VIDEOS] Error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load videos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadSubjectVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.subject.displayName,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.gradientEnd),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.secondaryGray,
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              Text(
                'Error Loading Videos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              Text(
                _errorMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryGray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.paddingLarge),
              ElevatedButton(onPressed: _onRefresh, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 64,
                color: AppTheme.secondaryGray,
              ),
              const SizedBox(height: AppTheme.paddingMedium),
              Text(
                'No Videos Found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              Text(
                'No videos available for ${widget.subject.displayName}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryGray),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      backgroundColor: AppTheme.surface,
      color: AppTheme.primary,
      child: Column(
        children: [
          // Subject Header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppTheme.paddingMedium),
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            decoration: AppTheme.gradientDecoration(),
            child: Row(
              children: [
                Icon(Icons.book, color: AppTheme.primaryWhite, size: 24),
                const SizedBox(width: AppTheme.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subject.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_videos.length} lesson${_videos.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Videos Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingMedium,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppTheme.paddingMedium,
                mainAxisSpacing: AppTheme.paddingMedium,
                childAspectRatio: 0.75,
              ),
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                final video = _videos[index];
                return VideoCard(
                  video: video,
                  progress: Provider.of<VideoProvider>(
                    context,
                    listen: false,
                  ).progressFor(video.id),
                  onTap: () => _openReels(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openReels(int index) {
    VideoReelsScreen.open(context, _videos, initialIndex: index);
  }
}
