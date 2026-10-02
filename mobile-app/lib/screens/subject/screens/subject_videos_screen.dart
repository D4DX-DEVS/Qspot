import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../model/subject_model.dart';
import '../provider/subject_videos_screen_provider.dart';
import '../../video/provider/video_provider.dart';
import '../../video/widgets/video_card.dart';
import '../../video/widgets/video_grid.dart';
import '../widgets/chapter_guide_sheet.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/home_palette.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/animation/count_up_text.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../video/screens/video_reels_screen.dart';

class SubjectVideosScreen extends StatefulWidget {
  final SubjectModel subject;

  const SubjectVideosScreen({super.key, required this.subject});

  @override
  State<SubjectVideosScreen> createState() => _SubjectVideosScreenState();
}

class _SubjectVideosScreenState extends State<SubjectVideosScreen> {
  final SubjectVideosScreenProvider _subjectVideos =
      SubjectVideosScreenProvider();

  @override
  void dispose() {
    _subjectVideos.dispose();
    super.dispose();
  }

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

  Future<void> _loadSubjectVideos() async {
    await _subjectVideos.loadSubjectVideos(
      widget.subject.id,
      // Watch status for these videos comes from the account (fetched once
      // per session by VideoProvider), not local storage.
      onLoaded: () async {
        if (!mounted) return;
        await Provider.of<VideoProvider>(context, listen: false).loadProgress();
      },
    );
  }

  Future<void> _onRefresh() async {
    await _loadSubjectVideos();
  }

  HomePalette get _p => HomePalette.of(context);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _subjectVideos,
      child: Consumer<SubjectVideosScreenProvider>(
        builder: (_, subjectVideos, __) => _buildPage(subjectVideos),
      ),
    );
  }

  Widget _buildPage(SubjectVideosScreenProvider subjectVideos) {
    return Scaffold(
      appBar: CommonAppBar(title: widget.subject.displayName),
      body: _buildBody(subjectVideos),
    );
  }

  Widget _buildBody(SubjectVideosScreenProvider subjectVideos) {
    final videos = subjectVideos.videos;
    if (subjectVideos.isLoading) {
      return Center(child: CircularProgressIndicator(color: _p.brand));
    }

    if (subjectVideos.errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.circleAlert, size: 64, color: _p.textMuted),
              const SizedBox(height: AppTheme.paddingMedium),
              Text(
                'Error Loading Videos',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: _p.text),
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              Text(
                subjectVideos.errorMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: _p.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.paddingLarge),
              ElevatedButton(onPressed: _onRefresh, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.clapperboard, size: 64, color: _p.textMuted),
              const SizedBox(height: AppTheme.paddingMedium),
              Text(
                'No Videos Found',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: _p.text),
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              Text(
                'No videos available for ${widget.subject.displayName}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: _p.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      backgroundColor: _p.card,
      color: _p.brand,
      child: Column(
        children: [
          // Subject Header
          StaggeredEntrance(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(AppTheme.paddingMedium),
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              decoration: BoxDecoration(
                gradient: _p.heroGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.book, color: AppColors.onPrimary, size: 24),
                  const SizedBox(width: AppTheme.paddingSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subject.displayName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        CountUpText(
                          '${videos.length} Lesson${videos.length != 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.onPrimary.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Videos Grid
          Expanded(
            child: VideoGrid(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingMedium,
              ),
              spacing: AppTheme.paddingMedium,
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return StaggeredEntrance(
                  index: index,
                  child: VideoCard(
                    video: video,
                    progress: Provider.of<VideoProvider>(
                      context,
                      listen: false,
                    ).progressFor(video.id),
                    onTap: () => _openReels(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openReels(int index) {
    VideoReelsScreen.open(context, _subjectVideos.videos, initialIndex: index);
  }
}
