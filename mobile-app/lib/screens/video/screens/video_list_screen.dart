import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/video_model.dart';
import '../provider/video_list_screen_provider.dart';
import '../provider/video_provider.dart';
import '../widgets/video_card.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/common_app_bar.dart';
import 'video_reels_screen.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key, this.startInSearchMode = false});

  /// When true, the search field opens focused immediately (e.g. tapping
  /// the Home search bar) instead of the plain video list.
  final bool startInSearchMode;

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  late final VideoListScreenProvider _search = VideoListScreenProvider(
    isSearching: widget.startInSearchMode,
  );
  final TextEditingController _searchController = TextEditingController();
  VideoProvider? _videoProvider;

  @override
  void initState() {
    super.initState();
    // We already have videos from the home screen, no need to fetch again
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Held so dispose() does not have to look a provider up from a
    // deactivated context.
    _videoProvider = Provider.of<VideoProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _search.dispose();
    // Clear search when leaving the screen
    _videoProvider?.clearSearch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _search,
      child: Consumer<VideoListScreenProvider>(
        builder: (_, search, __) => _buildPage(search),
      ),
    );
  }

  Widget _buildPage(VideoListScreenProvider search) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        title: 'All Videos',
        titleWidget: search.isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: AppFonts.regular(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search videos...',
                  hintStyle: AppFonts.regular(color: AppColors.textMuted),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  Provider.of<VideoProvider>(
                    context,
                    listen: false,
                  ).searchVideos(value);
                },
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(
              search.isSearching ? Icons.close : Icons.search,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              search.toggleSearching();
              if (!search.isSearching) {
                _searchController.clear();
                Provider.of<VideoProvider>(
                  context,
                  listen: false,
                ).clearSearch();
              }
            },
          ),
        ],
      ),
      body: Consumer<VideoProvider>(
        builder: (context, videoProvider, child) {
          if (videoProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (videoProvider.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingLarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    Text(
                      'Error Loading Videos',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    Text(
                      videoProvider.errorMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.paddingLarge),
                    ElevatedButton(
                      onPressed: () => videoProvider.refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Determine which videos to display
          final videos = videoProvider.isSearching
              ? videoProvider.searchResults
              : videoProvider.allVideos;

          if (videos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingLarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      videoProvider.isSearching
                          ? Icons.search_off
                          : Icons.video_library_outlined,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    Text(
                      videoProvider.isSearching
                          ? 'No Results Found'
                          : 'No Videos Available',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    Text(
                      videoProvider.isSearching
                          ? 'Try different keywords'
                          : 'Check back later for new content',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => videoProvider.refresh(),
            backgroundColor: AppColors.surface,
            color: AppColors.primary,
            child: GridView.builder(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppTheme.paddingMedium,
                mainAxisSpacing: AppTheme.paddingMedium,
                childAspectRatio: 0.75, // Adjust for video card proportions
              ),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return VideoCard(
                  video: video,
                  progress: Provider.of<VideoProvider>(
                    context,
                    listen: false,
                  ).progressFor(video.id),
                  onTap: () => _openReels(videos, index),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Tapping a card drops straight into the swipeable feed at that video.
  void _openReels(List<VideoModel> videos, int index) {
    VideoReelsScreen.open(context, videos, initialIndex: index);
  }
}
