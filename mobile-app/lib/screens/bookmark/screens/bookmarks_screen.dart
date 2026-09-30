import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../video/model/video_model.dart';
import '../provider/bookmark_provider.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/common_app_bar.dart';
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
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        title: 'Bookmarks',
        actions: [
          Consumer<BookmarkProvider>(
            builder: (context, bookmarkProvider, child) {
              if (bookmarkProvider.bookmarks.isEmpty) return const SizedBox();

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
                color: AppColors.background,
                onSelected: (value) {
                  if (value == 'clear_all') {
                    _showClearAllDialog();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, color: AppColors.textPrimary),
                        SizedBox(width: 8),
                        Text(
                          'Clear All',
                          style: AppFonts.medium(color: AppColors.textPrimary),
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: AppFonts.regular(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search bookmarks...',
          hintStyle: AppFonts.regular(color: AppColors.textMuted),
          prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.textMuted),
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
            style: AppFonts.regular(color: AppColors.textMuted, fontSize: 14),
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.border, width: 1),
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
                      style: AppFonts.semiBold(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    Text(
                      video.caption,
                      style: AppFonts.regular(
                        color: AppColors.textMuted,
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
                        style: AppFonts.regular(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              IconButton(
                onPressed: () => _removeBookmark(video),
                icon: const Icon(Icons.bookmark, color: AppColors.primary),
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
      color: AppColors.surfaceAlt,
      child: const Center(
        child: Icon(
          Icons.play_circle_outline,
          color: AppColors.textMuted,
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
            Icon(Icons.bookmark_border, size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'No Bookmarks Yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              'Start bookmarking videos to watch them later',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
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
            Icon(Icons.search_off, size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'No Results Found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              'Try searching with different keywords',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
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
            Icon(Icons.error_outline, size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              errorMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingLarge),
            ElevatedButton(
              onPressed: _onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
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
      AppSnackBar.show(
        context,
        message: 'Removed from your bookmarks',
        color: AppColors.success,
        actionLabel: 'Undo',
        onAction: () => bookmarkProvider.addBookmark(video),
      );
    });
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          'Clear All Bookmarks',
          style: AppFonts.medium(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove all bookmarks? This action cannot be undone.',
          style: AppFonts.regular(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppFonts.medium(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllBookmarks();
            },
            child: Text(
              'Clear All',
              style: AppFonts.medium(color: AppColors.danger),
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
      AppSnackBar.show(
        context,
        message: 'All your bookmarks have been removed',
        color: AppColors.success,
      );
    });
  }
}
