import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../services/today_service.dart';
import '../../../services/navigation_config_service.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/app_logo.dart';
import '../../../widgets/common/badged_icon_button.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/initials_avatar.dart';
import '../../../widgets/common/nav_list_card.dart';
import '../../../widgets/common/offline_notice.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/shortcut_tile.dart';
import '../../../widgets/common/stat_tile.dart';
import '../../assignment/screens/assignments_screen.dart';
import '../../auth/provider/auth_provider.dart';
import '../../banner/provider/banner_provider.dart';
import '../../banner/widgets/banner_carousel.dart';
import '../../bookmark/provider/bookmark_provider.dart';
import '../../common/provider/main_navigation_provider.dart';
import '../../common/widgets/home_theme_scope.dart';
import '../../notification/provider/notification_provider.dart';
import '../../notification/screens/notifications_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../question/screens/ask_question_screen.dart';
import '../../question/screens/my_questions_screen.dart';
import '../../quiz/screens/quiz_list_screen.dart';
import '../../schedule/screens/schedule_screen.dart';
import '../../speaker/provider/speaker_provider.dart';
import '../../subject/model/subject_model.dart';
import '../../subject/provider/subject_provider.dart';
import '../../subject/screens/subject_list_screen.dart';
import '../../subject/screens/subject_videos_screen.dart';
import '../../video/model/video_model.dart';
import '../../video/provider/video_provider.dart';
import '../../video/screens/video_reels_screen.dart';
import '../model/continue_lesson_info.dart';
import '../model/today_plan.dart';
import '../model/today_section.dart';
import '../provider/redesigned_home_screen_provider.dart';
import '../widgets/continue_lesson_card.dart';
import '../widgets/today_focus_stat_tile.dart';
import '../widgets/today_greeting.dart';
import '../widgets/today_hero_card.dart';
import '../widgets/today_sky_backdrop.dart';
import '../widgets/today_task_section.dart';

/// Task-first learner home. The legacy HomeScreen remains available for
/// backwards-compatible deep links while the shell uses this redesign.
class RedesignedHomeScreen extends StatefulWidget {
  const RedesignedHomeScreen({super.key});

  @override
  State<RedesignedHomeScreen> createState() => _RedesignedHomeScreenState();
}

class _RedesignedHomeScreenState extends State<RedesignedHomeScreen> {
  final RedesignedHomeScreenProvider _home = RedesignedHomeScreenProvider();
  Set<String> _visibleHomeSections = {
    for (final item in NavigationConfigService.defaultHomeSections) item.key,
  };

  late final MainNavigationProvider _nav;

  TodayOverview? get _today => _home.today;
  TodayPlan get _plan => _home.plan;

  @override
  void initState() {
    super.initState();
    _nav = context.read<MainNavigationProvider>()..addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  void _onTabChanged() =>
      _home.setTabVisible(_nav.keyAt(_nav.currentIndex) == 'today');

  Future<void> _initialize() async {
    await Future.wait([
      _loadNavigationConfig(),
      context.read<VideoProvider>().initialize(),
      context.read<SpeakerProvider>().initialize(),
      context.read<SubjectProvider>().initialize(),
      context.read<BookmarkProvider>().initialize(),
      context.read<NotificationProvider>().initialize(),
      context.read<BannerProvider>().initialize(),
      _loadToday(),
    ]);
  }

  Future<void> _loadNavigationConfig() async {
    final config = await NavigationConfigService.fetchConfig();
    if (!mounted) return;
    setState(() {
      _visibleHomeSections = {for (final item in config.homeSections) item.key};
    });
  }

  bool _showHomeSection(String key) => _visibleHomeSections.contains(key);

  Future<void> _loadToday() async {
    await _home.loadToday();
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<VideoProvider>().refresh(),
      context.read<SpeakerProvider>().refresh(),
      context.read<SubjectProvider>().refresh(),
      context.read<BannerProvider>().refresh(),
      _loadToday(),
    ]);
  }

  @override
  void dispose() {
    _nav.removeListener(_onTabChanged);
    _home.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _home,
      child: Consumer<RedesignedHomeScreenProvider>(
        builder: (_, home, __) => _buildPage(),
      ),
    );
  }

  Widget _buildPage() {
    return Scaffold(
      // The sky backdrop runs up behind the transparent bar.
      extendBodyBehindAppBar: true,
      appBar: _appBar(),
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
                  if (context.watch<VideoProvider>().offlineMode)
                    OfflineNotice(
                      message: context.read<VideoProvider>().errorMessage,
                    ),
                  if (_home.errorMessage != null)
                    _todayErrorBanner(_home.errorMessage!),
                  if (_showHomeSection('banners')) _banners(),
                  if (_showHomeSection('stats'))
                    StaggeredEntrance(index: 1, child: _statsStrip()),
                  if (_showHomeSection('stats') &&
                      _showHomeSection('shortcuts'))
                    const SizedBox(height: 18),
                  if (_showHomeSection('shortcuts'))
                    StaggeredEntrance(index: 2, child: _shortcuts()),
                  ..._sections(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _todayErrorBanner(String message) {
    final palette = HomePalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: palette.rose.soft,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _loadToday,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: palette.rose.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Today could not be refreshed. $message',
                    style: TextStyle(color: palette.text, fontSize: 13),
                  ),
                ),
                TextButton(onPressed: _loadToday, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Greeting over the sky and skyline, with the hero card resting on the
  /// bottom of the skyline.
  Widget _top() {
    final topInset = MediaQuery.paddingOf(context).top;
    final heroVisible = _showHomeSection('hero');
    final name = context.watch<AuthProvider>().user?.name ?? '';
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height:
              topInset +
              (heroVisible ? 178 : CommonAppBar.baseHeight + 24) +
              TodayGreeting.height,
          child: const TodaySkyBackdrop(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            topInset + CommonAppBar.baseHeight + 8,
            12,
            0,
          ),
          child: StaggeredEntrance(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TodayGreeting(name: name),
                if (heroVisible) _todayCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  CommonAppBar _appBar() {
    final palette = HomePalette.of(context);
    final auth = context.watch<AuthProvider>();
    final notifications = context.watch<NotificationProvider>();
    final name = (auth.user?.name ?? '').trim();
    return CommonAppBar(
      isDrawerNeeded: true,
      centerTitle: false,
      backgroundColor: palette.card,
      elevation: 0,
      titleWidget: const AppLogo(width: 154),
      actions: [
        BadgedIconButton(
          icon: LucideIcons.bell,
          tooltip: 'Notifications',
          count: notifications.unreadCount,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          label: 'Open Profile',
          button: true,
          excludeSemantics: true,
          child: PressableScale(
            haptic: true,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HomeThemeScope(child: ProfileScreen()),
                ),
              ),
              child: InitialsAvatar(
                name: name.isEmpty ? 'Learner' : name,
                size: 44,
                color: AppColors.authBrand,
                imageProvider: auth.user?.profileImageUrl == null
                    ? null
                    : NetworkImage(auth.user!.profileImageUrl!),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _todayCard() {
    final item = _plan.heroItem;
    if (item == null) {
      return TodayHeroCard(
        title: _plan.isCaughtUp
            ? "You're All Caught Up. Revise a Lesson!"
            : 'Your Next Small Win',
        onAction: _openLearn,
        showSparkle: true,
      );
    }
    final video = context.read<VideoProvider>().getVideoById(item.id);
    return TodayHeroCard(
      eyebrow: _itemLabel(item),
      meta: item.estimatedMinutes == null
          ? null
          : '${item.estimatedMinutes} min',
      title: item.title,
      thumbnailUrl: video?.thumbnailUrl,
      actionLabel: _itemActionLabel(item),
      progressLabel: _plan.openItemCount > 0
          ? '${_plan.openItemCount} items in your plan'
          : null,
      onAction: () => _openTodayItem(item, video),
    );
  }

  /// Announcement banners from the admin, right under the top card. Takes no
  /// room when there are none.
  Widget _banners() {
    return Consumer<BannerProvider>(
      builder: (_, banners, __) => banners.hasBanners
          ? Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: BannerCarousel(banners: banners.banners),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _statsStrip() {
    final palette = HomePalette.of(context);
    final provider = context.watch<VideoProvider>();
    final completed = provider.progressByVideo.values
        .where((p) => p.completed)
        .length;
    final total = provider.allVideos.where((v) => !v.isUpcoming).length;
    final stats = [
      StatTile(
        icon: LucideIcons.flame,
        color: palette.amber.color,
        value: '${_today?.currentStreak ?? 0}',
        label: 'Day Streak',
      ),
      StatTile(
        icon: LucideIcons.circleCheck,
        color: palette.teal.color,
        value: '$completed/$total',
        label: 'Lessons Done',
      ),
      TodayFocusStatTile(focus: _plan.focus, count: _plan.focusCount),
    ];
    // Tiles share the tallest one's height when a label wraps.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: stats[i]),
          ],
        ],
      ),
    );
  }

  Widget _shortcuts() {
    final palette = HomePalette.of(context);
    final tiles = [
      ShortcutTile(
        icon: LucideIcons.circleQuestionMark,
        label: 'Ask',
        tone: palette.mint,
        onTap: _openAsk,
      ),
      ShortcutTile(
        icon: LucideIcons.clipboardList,
        label: 'Assignments',
        tone: palette.amber,
        onTap: _openAssignments,
      ),
      ShortcutTile(
        icon: LucideIcons.calendarDays,
        label: 'Schedule',
        tone: palette.teal,
        onTap: _openSchedule,
      ),
      ShortcutTile(
        icon: LucideIcons.messageSquareText,
        label: 'My Questions',
        tone: palette.rose,
        onTap: _openMyQuestions,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(emoji: '⚡', title: 'Your Shortcuts'),
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

  /// Sections in the order the plan sets for this learner's work.
  List<Widget> _sections() {
    final plan = _plan;
    return [
      for (var i = 0; i < plan.sections.length; i++)
        if (_showHomeSection(_homeSectionKey(plan.sections[i])))
          _section(plan.sections[i], 3 + i),
    ];
  }

  String _homeSectionKey(TodaySection section) {
    switch (section) {
      case TodaySection.attention:
        return 'attention';
      case TodaySection.todo:
        return 'todo';
      case TodaySection.comingUp:
        return 'comingUp';
      case TodaySection.jumpBackIn:
        return 'jumpBackIn';
      case TodaySection.subjects:
        return 'subjects';
    }
  }

  Widget _section(TodaySection section, int index) {
    switch (section) {
      case TodaySection.attention:
        return _taskSection(section, _plan.attention, index);
      case TodaySection.todo:
        return _taskSection(section, _plan.todo, index);
      case TodaySection.comingUp:
        return _taskSection(section, _plan.comingUp, index);
      case TodaySection.jumpBackIn:
        return _continueSection(index);
      case TodaySection.subjects:
        return _subjectsSection(index);
    }
  }

  Widget _taskSection(
    TodaySection section,
    List<TodayLearningItem> items,
    int index,
  ) {
    return StaggeredEntrance(
      index: index,
      child: TodayTaskSection(
        section: section,
        items: items,
        onItemTap: (item) => _openTodayItem(
          item,
          context.read<VideoProvider>().getVideoById(item.id),
        ),
        // Opens the area of the first item, e.g. Assignments or Schedule.
        onSeeAll: () => _openTodayItem(items.first, null),
      ),
    );
  }

  Widget _continueSection(int index) {
    final palette = HomePalette.of(context);
    final tones = [
      palette.coral,
      palette.teal,
      palette.amber,
      palette.mint,
      palette.rose,
    ];
    // Wide enough to show a sliver of the next card, so it reads as swipeable.
    final cardWidth = (MediaQuery.sizeOf(context).width * 0.72)
        .clamp(230.0, 280.0)
        .toDouble();
    return Consumer<VideoProvider>(
      builder: (context, videos, _) {
        final items = videos.getVideosWithProgress().take(6).toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return StaggeredEntrance(
          index: index,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              SectionHeader(
                emoji: '🎬',
                title: 'Jump Back In',
                subtitle: 'Your Lessons Are Waiting. Finish What You Started!',
                actionLabel: 'See All',
                onAction: _openLearn,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                // Cards share the tallest one's height, whatever the text size.
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        ContinueLessonCard(
                          title: items[i].displayTitle,
                          subject: items[i].subjectName ?? 'Lesson',
                          thumbnailUrl: items[i].thumbnailUrl,
                          info: ContinueLessonInfo.from(
                            items[i],
                            videos.progressFor(items[i].id),
                          ),
                          tone: tones[i % tones.length],
                          width: cardWidth,
                          onTap: () => _openVideo(items[i]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _subjectsSection(int index) {
    final palette = HomePalette.of(context);
    return Consumer<SubjectProvider>(
      builder: (context, subjects, _) {
        final items = subjects.subjects.take(6).toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return StaggeredEntrance(
          index: index,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              SectionHeader(
                emoji: '📚',
                title: 'Choose a Subject',
                actionLabel: 'See All',
                onAction: _openLearn,
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                NavListCard(
                  icon: LucideIcons.bookOpen,
                  tone: i.isEven ? palette.teal : palette.coral,
                  title: items[i].displayName,
                  subtitle: 'Open Chapter',
                  onTap: () => _openSubject(items[i]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String? _itemLabel(TodayLearningItem item) {
    if (item.status == 'overdue') return 'NEEDS YOUR ATTENTION';
    if (item.kind == 'assignment') return 'ASSIGNMENT';
    if (item.kind == 'quiz') {
      return item.assessmentType == 'practical' ? 'PRACTICAL EXAM' : 'PRACTICE';
    }
    if (item.kind == 'schedule') return 'LIVE SESSION';
    if (item.status == 'in-progress') return 'CONTINUE LEARNING';
    return null;
  }

  String _itemActionLabel(TodayLearningItem item) {
    if (item.status == 'overdue') {
      return item.kind == 'video' ? 'Continue lesson' : 'Start now';
    }
    if (item.kind == 'assignment') return 'Open assignment';
    if (item.kind == 'quiz') return 'Start practice';
    if (item.kind == 'schedule') return 'View session';
    if (item.status == 'in-progress') return 'Continue lesson';
    return 'Start lesson';
  }

  void _openTodayItem(TodayLearningItem item, VideoModel? video) {
    if (item.kind == 'assignment') return _openAssignments();
    if (item.kind == 'quiz') return _openPractice();
    if (item.kind == 'schedule') return _openSchedule();
    if (video != null) return _openVideo(video);
    _openLearn();
  }

  void _openVideo(VideoModel video) {
    final provider = context.read<VideoProvider>();
    final feed = provider.allVideos.isNotEmpty ? provider.allVideos : [video];
    final index = feed.indexWhere((item) => item.id == video.id);
    VideoReelsScreen.open(
      context,
      feed,
      initialIndex: index < 0 ? 0 : index,
    ).then((_) => _loadToday());
  }

  /// Learn is a tab of the shell, so switch to it instead of pushing a page.
  void _openLearn() {
    if (_nav.hasKey('learn')) {
      _nav.setIndex(_nav.indexForKey('learn'));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeThemeScope(child: SubjectListScreen()),
      ),
    );
  }

  // The screens below can finish work, so Today reloads when they close.
  void _openSubject(SubjectModel subject) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          HomeThemeScope(child: SubjectVideosScreen(subject: subject)),
    ),
  ).then((_) => _loadToday());

  void _openPractice() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const QuizListScreen()),
  ).then((_) => _loadToday());

  void _openAssignments() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AssignmentsScreen()),
  ).then((_) => _loadToday());

  void _openAsk() => AskQuestionScreen.show(context);

  void _openSchedule() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ScheduleScreen()),
  ).then((_) => _loadToday());

  void _openMyQuestions() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const MyQuestionsScreen()),
  );
}
