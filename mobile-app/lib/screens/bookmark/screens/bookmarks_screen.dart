import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../video/model/video_model.dart';
import '../provider/bookmark_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/common/loading_skeleton.dart';
import '../../video/screens/video_player_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<BookmarkProvider>(context, listen: false).loadBookmarks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() {
    return Provider.of<BookmarkProvider>(
      context,
      listen: false,
    ).loadBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Bookmarks',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          Consumer<BookmarkProvider>(
            builder: (context, bookmarkProvider, child) {
              if (bookmarkProvider.bookmarks.isEmpty) return const SizedBox();

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
                color: AppTheme.background,
                onSelected: (value) {
                  if (value == 'clear_all') {
                    _showClearAllDialog();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, color: AppTheme.textPrimary),
                        SizedBox(width: 8),
                        Text(
                          'Clear All',
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<BookmarkProvider>(
        builder: (context, bookmarkProvider, child) {
          if (bookmarkProvider.isLoading &&
              bookmarkProvider.bookmarks.isEmpty) {
            return const LoadingSkeleton();
          }

          if (bookmarkProvider.hasError && bookmarkProvider.bookmarks.isEmpty) {
            return _buildErrorState(bookmarkProvider.errorMessage);
          }

          if (bookmarkProvider.bookmarks.isEmpty) {
            return _buildEmptyState();
          }

          final query = _searchController.text;
          final filtered = query.isEmpty
              ? bookmarkProvider.bookmarks
              : bookmarkProvider.searchBookmarks(query);

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: Column(
              children: [
                _buildSearchBar(),
                _buildBookmarksCount(filtered.length),
                Expanded(
                  child: filtered.isEmpty && query.isNotEmpty
                      ? _buildNoSearchResults()
                      : _buildBookmarksList(filtered),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search bookmarks...',
          hintStyle: TextStyle(color: AppTheme.secondaryGray),
          prefixIcon: Icon(Icons.search, color: AppTheme.secondaryGray),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.secondaryGray),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingMedium,
            vertical: AppTheme.paddingMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarksCount(int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
      child: Row(
        children: [
          Text(
            '$count bookmark${count != 1 ? 's' : ''}',
            style: TextStyle(color: AppTheme.secondaryGray, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList(List<VideoModel> videos) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      itemCount: videos.length,
      itemBuilder: (context, index) => _buildBookmarkCard(videos[index]),
    );
  }

  Widget _buildBookmarkCard(VideoModel video) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: InkWell(
        onTap: () => _navigateToVideoPlayer(video),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: SizedBox(
                  width: 120,
                  height: 68,
                  child: video.thumbnailUrl.isEmpty
                      ? _buildThumbnailPlaceholder()
                      : CachedNetworkImage(
                          imageUrl: video.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, error, stackTrace) {
                            return _buildThumbnailPlaceholder();
                          },
                        ),
                ),
              ),

              const SizedBox(width: AppTheme.paddingMedium),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.displayTitle,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    Text(
                      video.caption,
                      style: TextStyle(
                        color: AppTheme.secondaryGray,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (video.subjectName != null &&
                        video.subjectName!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.paddingSmall),
                      Text(
                        video.subjectName!,
                        style: TextStyle(
                          color: AppTheme.secondaryGray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              IconButton(
                onPressed: () => _removeBookmark(video),
                icon: const Icon(Icons.bookmark, color: AppTheme.gradientEnd),
                tooltip: 'Remove bookmark',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      color: AppTheme.surfaceAlt,
      child: const Center(
        child: Icon(
          Icons.play_circle_outline,
          color: AppTheme.textMuted,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: AppTheme.secondaryGray,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'No Bookmarks Yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              'Start bookmarking videos to watch them later',
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

  Widget _buildNoSearchResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.secondaryGray),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'No Results Found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              'Try searching with different keywords',
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

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.secondaryGray),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              errorMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingLarge),
            ElevatedButton(
              onPressed: _onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gradientStart,
                foregroundColor: AppTheme.onPrimary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToVideoPlayer(VideoModel video) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VideoPlayerScreen(video: video)),
    );
  }

  void _removeBookmark(VideoModel video) {
    final bookmarkProvider = Provider.of<BookmarkProvider>(
      context,
      listen: false,
    );
    bookmarkProvider.removeBookmark(video.id).then((success) {
      if (!mounted || !success) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Bookmark removed',
            style: TextStyle(color: AppTheme.onPrimary),
          ),
          backgroundColor: AppTheme.textPrimary,
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppTheme.accentAmber,
            onPressed: () => bookmarkProvider.addBookmark(video),
          ),
        ),
      );
    });
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text(
          'Clear All Bookmarks',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to remove all bookmarks? This action cannot be undone.',
          style: TextStyle(color: AppTheme.secondaryGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.secondaryGray),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllBookmarks();
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllBookmarks() {
    final bookmarkProvider = Provider.of<BookmarkProvider>(
      context,
      listen: false,
    );
    bookmarkProvider.clearAllBookmarks().then((success) {
      if (!mounted || !success) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All bookmarks cleared',
            style: TextStyle(color: AppTheme.onPrimary),
          ),
          backgroundColor: AppTheme.textPrimary,
        ),
      );
    });
  }
}
