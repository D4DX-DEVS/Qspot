import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../video/model/video_model.dart';
import '../../video/provider/video_provider.dart';
import '../../speaker/provider/speaker_provider.dart';
import '../../subject/provider/subject_provider.dart';
import '../../../widgets/common/see_all_button.dart';
import '../../../widgets/common/loading_skeleton.dart';
import '../../../themes/app_theme.dart';
import '../../video/screens/video_list_screen.dart';
import '../../video/screens/video_reels_screen.dart';
import '../../video/screens/video_questions_screen.dart';
import '../../subject/screens/subject_list_screen.dart';
import '../../../services/course_service.dart';
import '../widgets/about_course_sheet.dart';
import '../../notification/screens/notifications_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../quiz/screens/quiz_list_screen.dart';
import '../../assignment/screens/assignments_screen.dart';
import '../../schedule/screens/schedule_screen.dart';
import '../../bookmark/provider/bookmark_provider.dart';
import '../../../services/video_progress_service.dart';
import '../../../services/today_service.dart';
import '../../auth/provider/auth_provider.dart';
import '../../speaker/screens/faculties_screen.dart';
import '../../banner/provider/banner_provider.dart';
import '../../notification/provider/notification_provider.dart';
import '../../banner/widgets/banner_carousel.dart';

/// One of the four square shortcuts on the home screen.
class _HomeAction {
  const _HomeAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

enum _TodayItemKind {
  overdue,
  upcoming,
  continueWatching,
  practice,
  quiz,
  start,
}

class _TodayItem {
  const _TodayItem(this.video, this.kind, this.progress, [this.remote]);

  final VideoModel? video;
  final _TodayItemKind kind;
  final VideoProgressStatus? progress;
  final TodayLearningItem? remote;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CourseModel> _courses = [];
  TodayOverview? _todayOverview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
    _loadCourses();
  }

  /// Courses the app is running, shown as an "About this course" card.
  Future<void> _loadCourses() async {
    final courses = await CourseService.fetchActive();
    if (!mounted) return;
    setState(() => _courses = courses);
  }

  Widget _buildCoursesSection() {
    if (_courses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Courses',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ..._courses.map(
          (course) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => AboutCourseSheet.show(context, course),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.school_outlined,
                          color: AppTheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                            if (course.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                course.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Rounded search bar, like the reference home screen.
  Widget _buildSearchBar() {
    return InkWell(
      onTap: _navigateToVideoListWithSearch,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: AppTheme.textMuted, size: 20),
            SizedBox(width: 10),
            Text(
              'Search',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeData() async {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    final speakerProvider = Provider.of<SpeakerProvider>(
      context,
      listen: false,
    );
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    final bookmarkProvider = Provider.of<BookmarkProvider>(
      context,
      listen: false,
    );
    final bannerProvider = Provider.of<BannerProvider>(context, listen: false);

    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    await Future.wait([
      videoProvider.initialize(),
      _loadTodayOverview(),
      speakerProvider.initialize(),
      subjectProvider.initialize(),
      bookmarkProvider.initialize(),
      bannerProvider.initialize(),
      notificationProvider.initialize(),
    ]);
  }

  Future<void> _onRefresh() async {
    unawaited(_loadTodayOverview());
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    final speakerProvider = Provider.of<SpeakerProvider>(
      context,
      listen: false,
    );
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    final bannerProvider = Provider.of<BannerProvider>(context, listen: false);

    await Future.wait([
      videoProvider.refresh(),
      speakerProvider.refresh(),
      subjectProvider.refresh(),
      bannerProvider.refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/icons/Logo 01 Color.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.book,
                      color: AppTheme.gradientEnd,
                      size: 24,
                    );
                  },
                ),
              ),
            ),
            // const SizedBox(width: AppTheme.paddingSmall),
            // const Text(
            //   'QSpot',
            //   style: TextStyle(
            //     fontSize: 24,
            //     fontWeight: FontWeight.bold,
            //     color: AppTheme.primaryWhite,
            //   ),
            // ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final unreadCount = notificationProvider.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    onPressed: _navigateToNotifications,
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.textPrimary,
                      size: 24,
                    ),
                    tooltip: 'Notifications',
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.danger,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: AppTheme.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // The student themselves: tap to open the profile.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: _navigateToProfile,
              customBorder: const CircleBorder(),
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final name = (authProvider.user?.name ?? '').trim();
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initialsFor(name.isEmpty ? 'Student' : name),
                      style: const TextStyle(
                        color: AppTheme.onPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        backgroundColor: AppTheme.surface,
        color: AppTheme.primary,
        child: Consumer<VideoProvider>(
          builder: (context, videoProvider, child) {
            // Videos are the only data Home renders directly (Speakers/
            // Subjects are only pre-warmed here for other tabs — a failure
            // there must not blank Home, M23). Only gate the whole page on
            // the video feed itself, and only when there is nothing cached
            // yet to show.
            final hasAnyVideos =
                videoProvider.videosByDate.isNotEmpty ||
                videoProvider.latestVideo != null;

            if (videoProvider.isLoading && !hasAnyVideos) {
              return const LoadingSkeleton();
            }

            if (videoProvider.hasError && !hasAnyVideos) {
              return _buildErrorState(
                videoProvider.errorMessage,
                () => _initializeData(),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Who the student is, and a way back into their profile.
                  _buildGreeting(),

                  const SizedBox(height: 14),

                  // A background refresh failure with stale content still on
                  // screen gets a small inline notice + retry, not a blank
                  // page (M23).
                  if (videoProvider.hasError && hasAnyVideos)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildInlineSectionError(
                        videoProvider.errorMessage,
                        () => videoProvider.refresh(),
                      ),
                    ),

                  // Search
                  _buildTodaySection(videoProvider),

                  const SizedBox(height: AppTheme.paddingLarge),

                  _buildSearchBar(),

                  const SizedBox(height: AppTheme.paddingLarge),

                  // Recent videos: the latest six, at a glance.
                  _buildRecentVideos(videoProvider),

                  const SizedBox(height: AppTheme.paddingLarge),

                  // The four shortcuts, grouped into one strip.
                  _buildQuickAccess(),

                  if (_courses.isNotEmpty) ...[_buildCoursesSection()],

                  const SizedBox(height: AppTheme.paddingLarge),

                  // Banner Section
                  Consumer<BannerProvider>(
                    builder: (context, bannerProvider, child) {
                      debugPrint(
                        '🏠 [HOME] Banner Provider State - Has Banners: ${bannerProvider.hasBanners}, Count: ${bannerProvider.banners.length}',
                      );
                      if (bannerProvider.hasBanners) {
                        debugPrint(
                          '🏠 [HOME] Rendering BannerCarousel with ${bannerProvider.banners.length} banners',
                        );
                        return Column(
                          children: [
                            BannerCarousel(banners: bannerProvider.banners),
                            const SizedBox(height: AppTheme.paddingLarge),
                          ],
                        );
                      }
                      debugPrint('🏠 [HOME] No banners to display');
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Greeting with the student's name: their own corner of the home screen.
  Widget _buildGreeting() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final name = (authProvider.user?.name ?? '').trim();
        final classNumber = (authProvider.user?.classNumber ?? '').trim();

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assalamu Alaikum',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name.isNotEmpty ? name : 'Student',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (classNumber.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Class $classNumber',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// The six most recent episodes as a 3 × 2 poster grid.
  Widget _buildRecentVideos(VideoProvider videoProvider) {
    final recent = videoProvider.videosByDate.take(6).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent videos',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SeeAllButton(onPressed: _navigateToVideoList),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
            childAspectRatio: 0.62,
          ),
          itemCount: recent.length,
          itemBuilder: (context, index) {
            final video = recent[index];
            return _recentTile(video, videoProvider.progressFor(video.id));
          },
        ),
      ],
    );
  }

  _TodayItem? _nextTodayItem(VideoProvider videoProvider) {
    final overview = _todayOverview;
    final remoteNext =
        overview?.next ??
        (overview?.continueItems.isNotEmpty == true
            ? overview!.continueItems.first
            : null) ??
        (overview?.upcoming.isNotEmpty == true
            ? overview!.upcoming.first
            : null);
    if (remoteNext != null &&
        (remoteNext.id.isNotEmpty || remoteNext.title.isNotEmpty)) {
      final video = remoteNext.id.isEmpty
          ? null
          : videoProvider.getVideoById(remoteNext.id);
      return _TodayItem(
        video,
        _kindForRemote(remoteNext),
        video == null ? null : videoProvider.progressFor(video.id),
        remoteNext,
      );
    }

    final items = <_TodayItem>[];
    for (final video in videoProvider.allVideos) {
      final progress = videoProvider.progressFor(video.id);
      if (video.isUpcoming) {
        items.add(_TodayItem(video, _TodayItemKind.upcoming, progress));
      } else if (progress != null &&
          progress.status == 'in-progress' &&
          !progress.completed) {
        items.add(_TodayItem(video, _TodayItemKind.continueWatching, progress));
      } else if (progress?.completed == true &&
          !(progress?.quizAttempted ?? false) &&
          ((progress?.questionCount ?? 0) > 0 || video.questionCount > 0)) {
        items.add(_TodayItem(video, _TodayItemKind.practice, progress));
      } else if (progress?.completed != true) {
        items.add(_TodayItem(video, _TodayItemKind.start, progress));
      }
    }

    int priority(_TodayItemKind kind) => switch (kind) {
      _TodayItemKind.overdue => 0,
      _TodayItemKind.upcoming => 1,
      _TodayItemKind.continueWatching => 2,
      _TodayItemKind.practice => 3,
      _TodayItemKind.quiz => 3,
      _TodayItemKind.start => 4,
    };

    items.sort((a, b) {
      final byPriority = priority(a.kind).compareTo(priority(b.kind));
      if (byPriority != 0) return byPriority;
      if (a.kind == _TodayItemKind.upcoming) {
        final aDate =
            a.video?.date ?? a.remote?.releaseAt ?? DateTime.utc(9999);
        final bDate =
            b.video?.date ?? b.remote?.releaseAt ?? DateTime.utc(9999);
        return aDate.compareTo(bDate);
      }
      if (a.kind == _TodayItemKind.continueWatching) {
        final aDate = a.progress?.lastViewedAt;
        final bDate = b.progress?.lastViewedAt;
        if (aDate != null && bDate != null) return bDate.compareTo(aDate);
        if (aDate != null) return -1;
        if (bDate != null) return 1;
      }
      if (a.kind == _TodayItemKind.practice) {
        final aDate = a.progress?.completedAt;
        final bDate = b.progress?.completedAt;
        if (aDate != null && bDate != null) return aDate.compareTo(bDate);
        if (aDate != null) return -1;
        if (bDate != null) return 1;
      }
      final aDate = a.video?.date;
      final bDate = b.video?.date;
      if (aDate != null && bDate != null) return bDate.compareTo(aDate);
      if (aDate != null) return -1;
      if (bDate != null) return 1;
      return (a.video?.order ?? 0).compareTo(b.video?.order ?? 0);
    });

    return items.isEmpty ? null : items.first;
  }

  Future<void> _loadTodayOverview() async {
    final overview = await TodayService.fetch();
    if (mounted) setState(() => _todayOverview = overview);
  }

  _TodayItemKind _kindForRemote(TodayLearningItem item) {
    final status = item.status.toLowerCase();
    final kind = item.kind.toLowerCase();
    if (status == 'overdue' ||
        (item.dueAt != null && _isBeforeToday(item.dueAt!))) {
      return _TodayItemKind.overdue;
    }
    if (status == 'upcoming' || kind == 'upcoming') {
      return _TodayItemKind.upcoming;
    }
    if (kind == 'quiz') return _TodayItemKind.quiz;
    if (kind == 'practice' || kind == 'assignment') {
      return _TodayItemKind.practice;
    }
    if (status == 'in-progress' || (item.percent ?? 0) > 0) {
      return _TodayItemKind.continueWatching;
    }
    return _TodayItemKind.start;
  }

  Widget _buildTodaySection(VideoProvider videoProvider) {
    final item = _nextTodayItem(videoProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Next up',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (item == null) _buildEmptyTodayCard() else _buildTodayItemCard(item),
        const SizedBox(height: 10),
        _buildStreakCard(videoProvider),
      ],
    );
  }

  Widget _buildEmptyTodayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppTheme.success, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'You’re all caught up. Take a break or explore a subject.',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayItemCard(_TodayItem item) {
    final isUpcoming = item.kind == _TodayItemKind.upcoming;
    final isOverdue = item.kind == _TodayItemKind.overdue;
    final isPractice = item.kind == _TodayItemKind.practice;
    final isContinue = item.kind == _TodayItemKind.continueWatching;
    final video = item.video;
    final label = switch (item.kind) {
      _TodayItemKind.overdue =>
        item.remote?.dueAt != null && _isBeforeToday(item.remote!.dueAt!)
            ? 'Past due'
            : 'Due soon',
      _TodayItemKind.upcoming => 'Coming soon',
      _TodayItemKind.continueWatching => 'In progress',
      _TodayItemKind.practice => 'Practice ready',
      _TodayItemKind.quiz =>
        item.remote?.assessmentType == 'practical'
            ? 'Practical exam ready'
            : 'Quiz ready',
      _TodayItemKind.start => 'Ready to learn',
    };
    final detail = switch (item.kind) {
      _TodayItemKind.overdue =>
        item.remote?.dueAt == null
            ? 'This activity needs your attention'
            : 'Past due ${_formatDate(item.remote!.dueAt!)}',
      _TodayItemKind.upcoming =>
        item.remote?.releaseAt != null
            ? 'Available ${_formatDate(item.remote!.releaseAt!)}'
            : video?.date != null
            ? 'Available ${_formatDate(video!.date!)}'
            : 'This lesson is not available yet',
      _TodayItemKind.continueWatching => 'Pick up where you left off',
      _TodayItemKind.practice => 'You finished the lesson. Try its questions.',
      _TodayItemKind.quiz =>
        item.remote?.assessmentType == 'practical'
            ? 'A practical exam is ready to take.'
            : 'A quiz is ready to take.',
      _TodayItemKind.start => 'A new lesson is ready when you are',
    };
    final progress = item.progress;
    final title =
        video?.displayTitle ?? item.remote?.title ?? 'Learning activity';
    final subjectName = video?.subjectName ?? item.remote?.subject ?? '';
    final remotePercent = item.remote?.percent;
    final actionVideo = video;

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: item.remote?.kind.toLowerCase() == 'quiz'
            ? _navigateToQuiz
            : item.remote?.kind.toLowerCase() == 'schedule'
            ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScheduleScreen()),
              )
            : item.remote?.kind.toLowerCase() == 'assignment'
            ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AssignmentsScreen()),
              )
            : isUpcoming || actionVideo == null
            ? _navigateToVideoList
            : isPractice && progress?.completed == true
            ? () => VideoQuestionsScreen.open(context, actionVideo)
            : () => _navigateToVideoPlayer(actionVideo),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: video?.thumbnailUrl.isNotEmpty != true
                      ? Container(
                          color: AppTheme.primarySoft,
                          child: const Icon(
                            Icons.play_lesson_outlined,
                            color: AppTheme.primary,
                            size: 28,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: video!.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.primarySoft,
                            child: const Icon(
                              Icons.play_lesson_outlined,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isUpcoming
                            ? AppTheme.surfaceAlt
                            : isOverdue
                            ? const Color(0xFFFFEFED)
                            : isPractice
                            ? const Color(0xFFE8F3EC)
                            : AppTheme.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isUpcoming
                              ? AppTheme.textMuted
                              : isOverdue
                              ? AppTheme.danger
                              : isPractice
                              ? AppTheme.success
                              : AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subjectName.isNotEmpty
                          ? '$subjectName · $detail'
                          : item.remote?.estimatedMinutes != null
                          ? '${item.remote!.estimatedMinutes} min · $detail'
                          : detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    if (isContinue &&
                        ((progress?.percent ?? 0) > 0 ||
                            (remotePercent ?? 0) > 0)) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress != null && progress.percent > 0
                              ? progress.percent
                              : _progressFraction(remotePercent ?? 0),
                          minHeight: 4,
                          backgroundColor: AppTheme.surfaceAlt,
                          valueColor: const AlwaysStoppedAnimation(
                            AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isUpcoming ? Icons.chevron_right : Icons.arrow_forward,
                color: AppTheme.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard(VideoProvider videoProvider) {
    final now = DateTime.now();
    final activeToday = videoProvider.progressByVideo.values.any((progress) {
      final activity = progress.lastViewedAt;
      return activity != null &&
          activity.year == now.year &&
          activity.month == now.month &&
          activity.day == now.day;
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EA),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_outlined,
            color: AppTheme.warning,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              (_todayOverview?.currentStreak ?? 0) > 0
                  ? '${_todayOverview!.currentStreak} day learning streak${_todayOverview!.currentStreak == 1 ? '' : 's'}'
                  : _todayOverview?.summary.isNotEmpty == true
                  ? _todayOverview!.summary
                  : activeToday
                  ? 'Your progress is saved. Keep your learning rhythm gentle.'
                  : 'Build a learning streak one small lesson at a time.',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  bool _isBeforeToday(DateTime date) {
    final today = DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).isBefore(DateTime(today.year, today.month, today.day));
  }

  double _progressFraction(double percent) =>
      (percent > 1 ? percent / 100 : percent).clamp(0.0, 1.0);

  Widget _recentTile(VideoModel video, VideoProgressStatus? progress) {
    return InkWell(
      onTap: () => _navigateToVideoPlayer(video),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppTheme.surfaceAlt),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.surfaceAlt,
                      child: const Icon(
                        Icons.play_circle_outline,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  if (progress != null && progress.completed)
                    const Positioned(
                      right: 6,
                      top: 6,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: AppTheme.success,
                        child: Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                    )
                  else if (progress != null && progress.percent > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: progress.percent,
                        minHeight: 3,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(
                          AppTheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            video.displayTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// The four shortcuts in one strip, all styled identically: Videos,
  /// Subjects, Faculties and Quiz.
  Widget _buildQuickAccess() {
    final actions = <_HomeAction>[
      _HomeAction(
        icon: Icons.smart_display_outlined,
        label: 'Videos',
        onTap: _navigateToVideoList,
      ),
      _HomeAction(
        icon: Icons.menu_book_outlined,
        label: 'Subjects',
        onTap: _navigateToSubjectList,
      ),
      _HomeAction(
        icon: Icons.groups_outlined,
        label: 'Faculties',
        onTap: _navigateToFaculties,
      ),
      _HomeAction(
        icon: Icons.quiz_outlined,
        label: 'Quiz',
        onTap: _navigateToQuiz,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick access',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0)
                  Container(width: 1, height: 46, color: AppTheme.border),
                Expanded(child: _quickAccessItem(actions[i])),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickAccessItem(_HomeAction action) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppTheme.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, size: 21, color: AppTheme.primary),
            ),
            const SizedBox(height: 10),
            Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage, VoidCallback onRetry) {
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
              onPressed: onRetry,
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

  /// A slim inline banner for a section that failed to load while the rest
  /// of the page still has content (M23: one failing endpoint must not
  /// blank the whole Home).
  Widget _buildInlineSectionError(String message, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppTheme.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.isNotEmpty ? message : 'Could not refresh',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12.5,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToVideoPlayer(VideoModel video) {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    final feed = videoProvider.allVideos.isNotEmpty
        ? videoProvider.allVideos
        : videoProvider.videosByDate;
    final index = feed.indexWhere((item) => item.id == video.id);

    // A card outside the loaded feed (e.g. a stale cache entry) still opens,
    // it just has nothing to swipe to.
    if (index < 0) {
      VideoReelsScreen.open(context, [video]);
      return;
    }

    VideoReelsScreen.open(context, feed, initialIndex: index);
  }

  void _navigateToVideoList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VideoListScreen()),
    );
  }

  void _navigateToSubjectList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubjectListScreen()),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _navigateToFaculties() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FacultiesScreen()),
    );
  }

  void _navigateToQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuizListScreen()),
    );
  }

  /// First letters of the first two words, for the profile avatar.
  String _initialsFor(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => String.fromCharCode(part.runes.first).toUpperCase())
        .join();
    return parts.isEmpty ? '?' : parts;
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  void _navigateToVideoListWithSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VideoListScreen(startInSearchMode: true),
      ),
    );
  }
}
