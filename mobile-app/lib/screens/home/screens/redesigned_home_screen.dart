import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/today_service.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/nav_list_card.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/shortcut_tile.dart';
import '../../../widgets/common/stat_tile.dart';
import '../../assignment/screens/assignments_screen.dart';
import '../../auth/provider/auth_provider.dart';
import '../../bookmark/provider/bookmark_provider.dart';
import '../../common/widgets/home_theme_scope.dart';
import '../../notification/provider/notification_provider.dart';
import '../../notification/screens/notifications_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../question/screens/ask_question_screen.dart';
import '../../quiz/screens/quiz_list_screen.dart';
import '../../subject/provider/subject_provider.dart';
import '../../subject/screens/subject_list_screen.dart';
import '../../video/model/video_model.dart';
import '../../video/provider/video_provider.dart';
import '../../video/screens/video_reels_screen.dart';
import '../widgets/continue_lesson_card.dart';
import '../widgets/today_header.dart';
import '../widgets/today_hero_card.dart';
import '../widgets/today_sky_backdrop.dart';

/// Task-first learner home. The legacy HomeScreen remains available for
/// backwards-compatible deep links while the shell uses this redesign.
class RedesignedHomeScreen extends StatefulWidget {
  const RedesignedHomeScreen({super.key});

  @override
  State<RedesignedHomeScreen> createState() => _RedesignedHomeScreenState();
}

class _RedesignedHomeScreenState extends State<RedesignedHomeScreen> {
  TodayOverview? _today;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    await Future.wait([
      context.read<VideoProvider>().initialize(),
      context.read<SubjectProvider>().initialize(),
      context.read<BookmarkProvider>().initialize(),
      context.read<NotificationProvider>().initialize(),
      _loadToday(),
    ]);
  }

  Future<void> _loadToday() async {
    final result = await TodayService.fetch();
    if (mounted) setState(() => _today = result);
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<VideoProvider>().refresh(),
      context.read<SubjectProvider>().refresh(),
      _loadToday(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _top()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                32 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _statsStrip(),
                  const SizedBox(height: 18),
                  _shortcuts(),
                  _continueSection(),
                  _subjectsSection(),
                  _upcomingSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Greeting over the sky and skyline, with the hero card resting on the
  /// bottom of the skyline.
  Widget _top() {
    final topInset = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topInset + 250,
          child: const TodaySkyBackdrop(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(12, topInset + 14, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _header(),
              ),
              const SizedBox(height: 96),
              _todayCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header() {
    final auth = context.watch<AuthProvider>();
    final notifications = context.watch<NotificationProvider>();
    final name = (auth.user?.name ?? '').trim();
    return TodayHeader(
      greeting: _greeting(),
      name: name.isEmpty ? 'Learner' : name,
      unreadCount: notifications.unreadCount,
      onNotifications: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      ),
      onProfile: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeThemeScope(child: ProfileScreen()),
        ),
      ),
    );
  }

  Widget _todayCard() {
    final item = _today?.next;
    if (item == null || item.title.trim().isEmpty) {
      return TodayHeroCard(
        title: 'Your next small win',
        description: 'Pick a short lesson and keep your rhythm gentle.',
        actionLabel: 'Explore lessons',
        actionIcon: Icons.menu_book_rounded,
        onAction: _openLearn,
        showSparkle: true,
      );
    }
    final video = context.read<VideoProvider>().getVideoById(item.id);
    final urgent = item.status == 'overdue';
    final isTask = item.kind == 'quiz' || item.kind == 'assignment';
    return TodayHeroCard(
      eyebrow: _itemLabel(item),
      meta: item.estimatedMinutes == null
          ? null
          : '${item.estimatedMinutes} min',
      title: item.title,
      description: _itemDescription(item),
      actionLabel: urgent ? 'Handle now' : 'Start this',
      actionIcon: isTask
          ? Icons.edit_note_rounded
          : Icons.play_circle_outline_rounded,
      thumbnailUrl: video?.thumbnailUrl,
      onAction: () => _openTodayItem(item, video),
    );
  }

  Widget _statsStrip() {
    final palette = HomePalette.of(context);
    final provider = context.watch<VideoProvider>();
    final completed = provider.progressByVideo.values
        .where((p) => p.completed)
        .length;
    final total = provider.allVideos.where((v) => !v.isUpcoming).length;
    final nextCount = _today?.upcoming.length ?? 0;
    final stats = [
      StatTile(
        icon: Icons.local_fire_department_outlined,
        color: palette.coral.color,
        value: '${_today?.currentStreak ?? 0}',
        label: 'day streak',
      ),
      StatTile(
        icon: Icons.check_circle_outline_rounded,
        color: palette.teal.color,
        value: '$completed/$total',
        label: 'lessons done',
      ),
      StatTile(
        icon: Icons.event_note_outlined,
        color: palette.amber.color,
        value: '$nextCount',
        label: 'coming up',
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: stats[i]),
        ],
      ],
    );
  }

  Widget _shortcuts() {
    final palette = HomePalette.of(context);
    final tiles = [
      ShortcutTile(
        icon: Icons.menu_book_rounded,
        label: 'Learn',
        tone: palette.rose,
        onTap: _openLearn,
      ),
      ShortcutTile(
        icon: Icons.edit_note_rounded,
        label: 'Practice',
        tone: palette.coral,
        onTap: _openPractice,
      ),
      ShortcutTile(
        icon: Icons.assignment_outlined,
        label: 'Assignments',
        tone: palette.amber,
        onTap: _openAssignments,
      ),
      ShortcutTile(
        icon: Icons.help_outline_rounded,
        label: 'Ask',
        tone: palette.mint,
        onTap: _openAsk,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Your shortcuts'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: tiles[i]),
            ],
          ],
        ),
      ],
    );
  }

  Widget _continueSection() {
    return Consumer<VideoProvider>(
      builder: (context, videos, _) {
        final items = videos.getVideosWithProgress().take(6).toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            SectionHeader(
              title: 'Pick up where you left off',
              actionLabel: 'See all',
              onAction: _openLearn,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final video = items[index];
                  final progress = videos.progressFor(video.id);
                  final percent = progress?.percent ?? 0;
                  return ContinueLessonCard(
                    title: video.displayTitle,
                    subject: video.subjectName ?? 'Lesson',
                    thumbnailUrl: video.thumbnailUrl,
                    progress: percent,
                    status: progress?.completed == true
                        ? 'Completed'
                        : '${(percent * 100).round()}% watched',
                    onTap: () => _openVideo(video),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _subjectsSection() {
    final palette = HomePalette.of(context);
    return Consumer<SubjectProvider>(
      builder: (context, subjects, _) {
        final items = subjects.subjects.take(6).toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            SectionHeader(
              title: 'Choose a subject',
              actionLabel: 'See all',
              onAction: _openLearn,
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              NavListCard(
                icon: Icons.auto_stories_outlined,
                tone: i.isEven ? palette.teal : palette.coral,
                title: items[i].displayName,
                subtitle: 'Open chapter',
                onTap: _openLearn,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _upcomingSection() {
    final palette = HomePalette.of(context);
    final items =
        _today?.upcoming.take(4).toList() ?? const <TodayLearningItem>[];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        SectionHeader(
          title: 'Due work',
          actionLabel: 'See all',
          onAction: _openPractice,
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _upcomingCard(items[i], palette),
        ],
      ],
    );
  }

  Widget _upcomingCard(TodayLearningItem item, HomePalette palette) {
    final tone = item.status == 'overdue' ? palette.coral : palette.rose;
    return NavListCard(
      icon: _iconForKind(item.kind),
      tone: tone,
      title: item.title,
      subtitle: _upcomingMeta(item),
      subtitleColor: tone.color,
      onTap: () => _openTodayItem(
        item,
        context.read<VideoProvider>().getVideoById(item.id),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _itemLabel(TodayLearningItem item) {
    if (item.status == 'overdue') return 'NEEDS YOUR ATTENTION';
    if (item.kind == 'assignment') return 'ASSIGNMENT';
    if (item.kind == 'quiz') {
      return item.assessmentType == 'practical' ? 'PRACTICAL EXAM' : 'PRACTICE';
    }
    if (item.kind == 'schedule') return 'LIVE SESSION';
    if (item.status == 'in-progress') return 'CONTINUE LEARNING';
    return "TODAY'S NEXT STEP";
  }

  String _itemDescription(TodayLearningItem item) {
    if (item.status == 'overdue') return 'You can make progress on this now.';
    if (item.kind == 'assignment') {
      return 'Submit your work before the due date.';
    }
    if (item.kind == 'quiz') {
      return item.assessmentType == 'practical'
          ? 'Show what you can do with a practical task.'
          : 'Check your understanding with a short practice set.';
    }
    if (item.status == 'in-progress') return 'Pick up where you left off.';
    return 'A focused session is waiting for you.';
  }

  String _upcomingMeta(TodayLearningItem item) {
    if (item.status == 'overdue') return 'Past due - handle now';
    if (item.dueAt != null) return 'Due ${_shortDate(item.dueAt!)}';
    if (item.releaseAt != null) {
      return 'Available ${_shortDate(item.releaseAt!)}';
    }
    return item.kind == 'quiz' ? 'Ready to practice' : 'Open when ready';
  }

  String _shortDate(DateTime date) => '${date.day}/${date.month}';

  IconData _iconForKind(String kind) {
    switch (kind) {
      case 'assignment':
        return Icons.assignment_outlined;
      case 'quiz':
        return Icons.edit_note_outlined;
      case 'schedule':
        return Icons.video_call_outlined;
      default:
        return Icons.play_lesson_outlined;
    }
  }

  void _openTodayItem(TodayLearningItem item, VideoModel? video) {
    if (item.kind == 'assignment') return _openAssignments();
    if (item.kind == 'quiz') return _openPractice();
    if (video != null) return _openVideo(video);
    _openLearn();
  }

  void _openVideo(VideoModel video) {
    final provider = context.read<VideoProvider>();
    final feed = provider.allVideos.isNotEmpty ? provider.allVideos : [video];
    final index = feed.indexWhere((item) => item.id == video.id);
    VideoReelsScreen.open(context, feed, initialIndex: index < 0 ? 0 : index);
  }

  void _openLearn() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const HomeThemeScope(child: SubjectListScreen()),
    ),
  );

  void _openPractice() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const QuizListScreen()),
  );

  void _openAssignments() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AssignmentsScreen()),
  );

  void _openAsk() => AskQuestionScreen.show(context);
}
