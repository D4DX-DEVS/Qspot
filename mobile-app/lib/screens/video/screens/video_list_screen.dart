import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/video_model.dart';
import '../provider/video_provider.dart';
import '../widgets/video_card.dart';
import '../../../themes/app_theme.dart';
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
  late bool _isSearching = widget.startInSearchMode;
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
    // Clear search when leaving the screen
    _videoProvider?.clearSearch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search videos...',
                  hintStyle: TextStyle(color: AppTheme.secondaryGray),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  Provider.of<VideoProvider>(
                    context,
                    listen: false,
                  ).searchVideos(value);
                },
              )
            : const Text(
                'All Videos',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: AppTheme.textPrimary,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  Provider.of<VideoProvider>(
                    context,
                    listen: false,
                  ).clearSearch();
                }
              });
            },
          ),
        ],
      ),
      body: Consumer<VideoProvider>(
        builder: (context, videoProvider, child) {
          if (videoProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.gradientEnd),
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
                      color: AppTheme.secondaryGray,
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    Text(
                      'Error Loading Videos',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    Text(
                      videoProvider.errorMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryGray,
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
                      color: AppTheme.secondaryGray,
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    Text(
                      videoProvider.isSearching
                          ? 'No Results Found'
                          : 'No Videos Available',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    Text(
                      videoProvider.isSearching
                          ? 'Try different keywords'
                          : 'Check back later for new content',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryGray,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => videoProvider.refresh(),
            backgroundColor: AppTheme.surface,
            color: AppTheme.primary,
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
