import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../video/model/video_model.dart';
import '../provider/bookmark_provider.dart';
import '../provider/bookmarks_screen_provider.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/loading_skeleton.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../../widgets/common/surface_card.dart';
import '../../common/widgets/home_theme_scope.dart';
import '../../video/screens/video_player_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();
  final BookmarksScreenProvider _screen = BookmarksScreenProvider();

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
    _screen.dispose();
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
    // Burgundy home theme; the page reads colours from the context inside it.
    return HomeThemeScope(
      child: ChangeNotifierProvider.value(
        value: _screen,
        child: Consumer<BookmarksScreenProvider>(
          builder: (context, screen, _) => _buildPage(context, screen),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, BookmarksScreenProvider screen) {
    final p = HomePalette.of(context);
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Bookmarks',
        actions: [
          Consumer<BookmarkProvider>(
            builder: (context, bookmarkProvider, child) {
              if (bookmarkProvider.bookmarks.isEmpty) return const SizedBox();

              return PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: p.text),
                color: p.card,
                onSelected: (value) {
                  if (value == 'clear_all') {
                    _showClearAllDialog(context, p);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, color: p.text),
                        const SizedBox(width: 8),
                        Text(
                          'Clear All',
                          style: AppFonts.medium(color: p.text),
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
            return _buildErrorState(p, bookmarkProvider.errorMessage);
          }

          if (bookmarkProvider.bookmarks.isEmpty) {
            return _buildEmptyState(p);
          }

          final query = screen.query;
          final filtered = screen.filter(bookmarkProvider);

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: Column(
              children: [
                _buildSearchBar(p),
                _buildBookmarksCount(p, filtered.length),
                Expanded(
                  child: filtered.isEmpty && query.isNotEmpty
                      ? _buildNoSearchResults(p)
                      : _buildBookmarksList(p, filtered),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(HomePalette p) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.cardBorder, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _screen.setQuery,
        cursorColor: p.brand,
        style: AppFonts.regular(color: p.text),
        decoration: InputDecoration(
          hintText: 'Search bookmarks...',
          hintStyle: AppFonts.regular(color: p.textMuted),
          prefixIcon: Icon(Icons.search, color: p.textMuted),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: p.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    _screen.setQuery('');
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

  Widget _buildBookmarksCount(HomePalette p, int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
      child: Row(
        children: [
          Text(
            '$count bookmark${count != 1 ? 's' : ''}',
            style: AppFonts.regular(color: p.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList(HomePalette p, List<VideoModel> videos) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      itemCount: videos.length,
      itemBuilder: (context, index) => _buildBookmarkCard(p, videos[index]),
    );
  }

  Widget _buildBookmarkCard(HomePalette p, VideoModel video) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      child: SurfaceCard(
        onTap: () => _navigateToVideoPlayer(video),
        radius: 16,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 120,
                height: 68,
                child: video.thumbnailUrl.isEmpty
                    ? _buildThumbnailPlaceholder(p)
                    : CachedNetworkImage(
                        imageUrl: video.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, error, stackTrace) {
                          return _buildThumbnailPlaceholder(p);
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
                    style: AppFonts.semiBold(color: p.text, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.paddingSmall),
                  Text(
                    video.caption,
                    style: AppFonts.regular(color: p.textMuted, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (video.subjectName != null &&
                      video.subjectName!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.paddingSmall),
                    Text(
                      video.subjectName!,
                      style: AppFonts.semiBold(color: p.brand, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),

            IconButton(
              onPressed: () => _removeBookmark(video),
              icon: Icon(Icons.bookmark, color: p.brand),
              tooltip: 'Remove bookmark',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder(HomePalette p) {
    return Container(
      color: p.brandSoft,
      child: Center(
        child: Icon(Icons.play_circle_outline, color: p.brand, size: 32),
      ),
    );
  }

  Widget _buildEmptyState(HomePalette p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SoftIconTile(
              icon: Icons.bookmark_border,
              tone: p.rose,
              size: 84,
              circle: true,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'No Bookmarks Yet',
              style: AppFonts.bold(color: p.text, fontSize: 19),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              'Start bookmarking videos to watch them later',
              style: AppFonts.regular(
                color: p.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(HomePalette p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SoftIconTile(
              icon: Icons.search_off,
              tone: p.rose,
              size: 84,
              circle: true,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'No Results Found',
              style: AppFonts.bold(color: p.text, fontSize: 19),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              'Try searching with different keywords',
              style: AppFonts.regular(
                color: p.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(HomePalette p, String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SoftIconTile(
              icon: Icons.error_outline,
              tone: p.rose,
              size: 84,
              circle: true,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'Something went wrong',
              style: AppFonts.bold(color: p.text, fontSize: 19),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              errorMessage,
              style: AppFonts.regular(
                color: p.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingLarge),
            ElevatedButton(
              onPressed: _onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: p.brand,
                foregroundColor: p.card,
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

  void _showClearAllDialog(BuildContext scopedContext, HomePalette p) {
    showDialog(
      context: scopedContext,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All Bookmarks',
          style: AppFonts.medium(color: p.text),
        ),
        content: Text(
          'Are you sure you want to remove all bookmarks? This action cannot be undone.',
          style: AppFonts.regular(color: p.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppFonts.medium(color: p.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllBookmarks();
            },
            child: Text('Clear All', style: AppFonts.medium(color: p.error)),
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
