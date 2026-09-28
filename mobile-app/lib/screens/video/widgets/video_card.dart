import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../model/video_model.dart';
import '../../../services/video_progress_service.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../bookmark/provider/bookmark_provider.dart';
import '../../schedule/service/alarm_service.dart';

class VideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  /// Watch state for the signed-in user: not-started / in-progress / completed.
  final VideoProgressStatus? progress;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
    this.width = 140,
    this.height = 180,
    this.progress,
  });

  void _toggleBookmark(BuildContext context, VideoModel video) async {
    final bookmarkProvider = Provider.of<BookmarkProvider>(
      context,
      listen: false,
    );
    final success = await bookmarkProvider.toggleBookmark(video);

    if (success && context.mounted) {
      final isBookmarked = bookmarkProvider.isBookmarkedSync(video.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBookmarked ? 'Added to bookmarks' : 'Removed from bookmarks',
            style: AppFonts.regular(color: AppTheme.onPrimary),
          ),
          backgroundColor: AppTheme.textPrimary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _setVideoReminder(BuildContext context, VideoModel video) async {
    if (video.date == null) return;

    try {
      final alarmService = AlarmService();
      final success = await alarmService.scheduleVideoReminder(
        video.id,
        video.displayTitle,
        video.date!,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder set for ${video.upcomingDateFormatted}'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set reminder: ${e.toString()}'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpcoming = video.isUpcoming;

    return SizedBox(
      width: width,
      height: height,
      child: Card(
        elevation: 0,
        color: AppTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          side: const BorderSide(color: AppTheme.border),
        ),
        child: InkWell(
          onTap: isUpcoming ? null : onTap, // Disable tap for upcoming videos
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppTheme.radiusMedium),
                        topRight: Radius.circular(AppTheme.radiusMedium),
                      ),
                      child: video.thumbnailUrl.isEmpty
                          ? Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: AppTheme.surfaceAlt,
                              child: Icon(
                                Icons.video_library,
                                size: 24,
                                color: AppTheme.secondaryGray,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: video.thumbnailUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppTheme.surfaceAlt,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.gradientEnd,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppTheme.surfaceAlt,
                                child: Icon(
                                  Icons.video_library,
                                  size: 24,
                                  color: AppTheme.secondaryGray,
                                ),
                              ),
                            ),
                    ),

                    // Watch status, from the signed-in account
                    if (progress != null && progress!.status != 'not-started')
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: progress!.completed
                                ? AppTheme.success
                                : AppTheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                progress!.completed
                                    ? Icons.check_circle
                                    : Icons.play_circle_fill,
                                size: 11,
                                color: AppTheme.onPrimary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                progress!.completed
                                    ? 'Completed'
                                    : 'In progress',
                                style: AppFonts.semiBold(
                                  color: AppTheme.onPrimary,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Watch progress bar
                    if (progress != null &&
                        !progress!.completed &&
                        progress!.percent > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            topRight: Radius.circular(2),
                          ),
                          child: LinearProgressIndicator(
                            value: progress!.percent,
                            minHeight: 3,
                            backgroundColor: AppTheme.border,
                            valueColor: const AlwaysStoppedAnimation(
                              AppTheme.primary,
                            ),
                          ),
                        ),
                      ),

                    // Bookmark button: keep the visual icon compact while
                    // exposing a full 44px touch target and screen-reader label.
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Consumer<BookmarkProvider>(
                        builder: (context, bookmarkProvider, child) {
                          final isBookmarked = bookmarkProvider
                              .isBookmarkedSync(video.id);
                          return Semantics(
                            label: isBookmarked
                                ? 'Remove bookmark'
                                : 'Bookmark video',
                            button: true,
                            child: IconButton(
                              onPressed: () => _toggleBookmark(context, video),
                              icon: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isBookmarked
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: isBookmarked
                                      ? AppTheme.gradientEnd
                                      : AppTheme.primaryWhite,
                                  size: 16,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Duration badge or Live indicator
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: video.isLiveVideo
                              ? AppTheme.danger
                              : Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: video.isLiveVideo
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryWhite,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'LIVE',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppTheme.primaryWhite,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              )
                            : Text(
                                video.formattedDuration,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppTheme.primaryWhite,
                                      fontSize: 10,
                                    ),
                              ),
                      ),
                    ),

                    // Play icon overlay (only show for available videos)
                    if (!isUpcoming)
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            iconSize: 20,
                            icon: const Icon(
                              Icons.play_arrow,
                              color: AppTheme.primaryWhite,
                            ),
                            onPressed: onTap,
                          ),
                        ),
                      ),

                    // Upcoming overlay
                    if (isUpcoming)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.85),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(AppTheme.radiusMedium),
                              topRight: Radius.circular(AppTheme.radiusMedium),
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.schedule,
                                      color: AppTheme.primaryWhite,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'UPCOMING',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppTheme.primaryWhite,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                  ),
                                  child: Text(
                                    video.upcomingDateFormatted,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppTheme.primaryWhite,
                                          fontSize: 9,
                                        ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _setVideoReminder(context, video),
                                icon: const Icon(
                                  Icons.notifications_active,
                                  size: 12,
                                ),
                                label: Text(
                                  'Remind Me',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.gradientStart,
                                  foregroundColor: AppTheme.primaryWhite,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSmall,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Video info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.paddingSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          video.displayTitle,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Date
                      if (video.formattedDate.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          video.formattedDate,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppTheme.secondaryGray,
                                fontSize: 10,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
