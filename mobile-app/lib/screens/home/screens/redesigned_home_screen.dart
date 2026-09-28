import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/today_service.dart';
import '../../../services/video_progress_service.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../assignment/screens/assignments_screen.dart';
import '../../auth/provider/auth_provider.dart';
import '../../bookmark/provider/bookmark_provider.dart';
import '../../notification/provider/notification_provider.dart';
import '../../notification/screens/notifications_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../question/screens/ask_question_screen.dart';
import '../../quiz/screens/quiz_list_screen.dart';
import '../../subject/model/subject_model.dart';
import '../../subject/provider/subject_provider.dart';
import '../../subject/screens/subject_list_screen.dart';
import '../../video/model/video_model.dart';
import '../../video/provider/video_provider.dart';
import '../../video/screens/video_reels_screen.dart';

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
      backgroundColor: AppTheme.background,
      appBar: CommonAppBar(
        title: _greeting(),
        centerTitle: false,
        actions: _appBarActions(),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                2,
                16,
                32 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _todayCard(),
                  const SizedBox(height: 16),
                  _statsStrip(),
                  const SizedBox(height: 16),
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

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final name = (auth.user?.name ?? '').trim();
          final first = name.isEmpty ? 'learner' : name.split(' ').first;
          return Text(
            'Ready for a small win, $first?',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.extraBold(
              color: AppTheme.textPrimary,
              fontSize: 20,
            ),
          );
        },
      ),
    );
  }

  List<Widget> _appBarActions() {
    return [
      Consumer<NotificationProvider>(
        builder: (context, notifications, _) => _headerIcon(
          Icons.notifications_none_rounded,
          'Notifications',
          notifications.unreadCount,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
      ),
      const SizedBox(width: 2),
      Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final name = (auth.user?.name ?? 'Learner').trim();
          return Semantics(
            label: 'Open profile',
            button: true,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primary,
                child: Text(
                  _initials(name),
                  style: AppFonts.extraBold(color: AppTheme.onPrimary),
                ),
              ),
            ),
          );
        },
      ),
      const SizedBox(width: 12),
    ];
  }

  Widget _headerIcon(
    IconData icon,
    String label,
    int badge,
    VoidCallback onTap,
  ) {
    return Semantics(
      label: label,
      button: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(onPressed: onTap, tooltip: label, icon: Icon(icon)),
          if (badge > 0)
            Positioned(
              right: 5,
              top: 4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  textAlign: TextAlign.center,
                  style: AppFonts.extraBold(color: Colors.white, fontSize: 9),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _todayCard() {
    final item = _today?.next;
    final video = item == null
        ? null
        : context.read<VideoProvider>().getVideoById(item.id);
    final hasItem = item != null && item.title.trim().isNotEmpty;
    final urgent = item?.status == 'overdue';
    return Container(
      constraints: const BoxConstraints(minHeight: 186),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: urgent ? const Color(0xFF8D3F34) : AppTheme.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: hasItem ? _todayContent(item, video, urgent) : _emptyToday(),
    );
  }

  Widget _todayContent(TodayLearningItem item, VideoModel? video, bool urgent) {
    final kind = item.kind;
    final isQuiz = kind == 'quiz';
    final isAssignment = kind == 'assignment';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              urgent ? Icons.priority_high_rounded : Icons.wb_sunny_outlined,
              color: Colors.white.withValues(alpha: 0.85),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _itemLabel(item),
              style: AppFonts.extraBold(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            if (item.estimatedMinutes != null)
              Text(
                '${item.estimatedMinutes} min',
                style: AppFonts.regular(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.extraBold(
            color: Colors.white,
            fontSize: 21,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _itemDescription(item),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.regular(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _openTodayItem(item, video),
                icon: Icon(
                  isQuiz || isAssignment
                      ? Icons.arrow_forward_rounded
                      : Icons.play_arrow_rounded,
                  size: 18,
                ),
                label: Text(urgent ? 'Handle now' : 'Start this'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: urgent
                      ? const Color(0xFF8D3F34)
                      : AppTheme.primary,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            if (video?.thumbnailUrl.isNotEmpty == true) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: video!.thumbnailUrl,
                  width: 64,
                  height: 48,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _mediaFallback(),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _emptyToday() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'Your next small win',
                style: AppFonts.extraBold(color: Colors.white, fontSize: 21),
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Pick a short lesson and keep your rhythm gentle.',
          style: AppFonts.regular(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _openLearn,
          icon: const Icon(Icons.explore_outlined, size: 18),
          label: const Text('Explore lessons'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.55)),
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statsStrip() {
    final provider = context.watch<VideoProvider>();
    final completed = provider.progressByVideo.values
        .where((p) => p.completed)
        .length;
    final total = provider.allVideos.where((v) => !v.isUpcoming).length;
    final nextCount = _today?.upcoming.length ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          _metric(
            Icons.local_fire_department_outlined,
            '${_today?.currentStreak ?? 0}',
            'day streak',
            AppTheme.accent,
          ),
          _metric(
            Icons.check_circle_outline,
            '$completed/$total',
            'lessons done',
            AppTheme.success,
          ),
          _metric(
            Icons.event_note_outlined,
            '$nextCount',
            'coming up',
            AppTheme.warning,
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              children: [
                Text(
                  value,
                  style: AppFonts.extraBold(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.regular(
                    color: AppTheme.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shortcuts() {
    final actions = [
      _Action(Icons.menu_book_outlined, 'Learn', _openLearn, AppTheme.primary),
      _Action(
        Icons.edit_note_outlined,
        'Practice',
        _openPractice,
        AppTheme.accent,
      ),
      _Action(
        Icons.assignment_outlined,
        'Assignments',
        _openAssignments,
        AppTheme.warning,
      ),
      _Action(Icons.help_outline_rounded, 'Ask', _openAsk, AppTheme.success),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Your shortcuts', null),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _shortcut(actions[i])),
            ],
          ],
        ),
      ],
    );
  }

  Widget _shortcut(_Action action) {
    return Semantics(
      label: action.label,
      button: true,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            color: action.color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: action.color.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Icon(action.icon, color: action.color, size: 23),
              const SizedBox(height: 8),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppFonts.bold(color: AppTheme.textPrimary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
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
            const SizedBox(height: 16),
            _sectionHeader('Pick up where you left off', _openLearn),
            const SizedBox(height: 12),
            SizedBox(
              height: 164,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final video = items[index];
                  return _continueCard(video, videos.progressFor(video.id));
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _continueCard(VideoModel video, VideoProgressStatus? progress) {
    final percent = progress?.percent ?? 0;
    return SizedBox(
      width: 212,
      child: InkWell(
        onTap: () => _openVideo(video),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _mediaFallback(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      video.subjectName ?? 'Lesson',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.regular(
                        color: AppTheme.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.displayTitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.bold(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 4,
                        backgroundColor: AppTheme.surfaceAlt,
                        valueColor: const AlwaysStoppedAnimation(
                          AppTheme.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress?.completed == true
                          ? 'Completed'
                          : '${(percent * 100).round()}% watched',
                      style: AppFonts.regular(
                        color: AppTheme.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subjectsSection() {
    return Consumer<SubjectProvider>(
      builder: (context, subjects, _) {
        final items = subjects.subjects.take(6).toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _sectionHeader('Choose a subject', _openLearn),
            const SizedBox(height: 12),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _subjectCard(items[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _subjectCard(SubjectModel subject) {
    return SizedBox(
      width: double.infinity,
      height: 76,
      child: InkWell(
        onTap: _openLearn,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.auto_stories_outlined,
                  color: AppTheme.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.extraBold(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Open chapter',
                      style: AppFonts.regular(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _upcomingSection() {
    final items =
        _today?.upcoming.take(4).toList() ?? const <TodayLearningItem>[];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _sectionHeader('Due work', _openPractice),
        const SizedBox(height: 12),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _upcomingRow(items[i]),
        ],
      ],
    );
  }

  Widget _upcomingRow(TodayLearningItem item) {
    final color = item.status == 'overdue' ? AppTheme.danger : AppTheme.primary;
    return InkWell(
      onTap: () => _openTodayItem(
        item,
        context.read<VideoProvider>().getVideoById(item.id),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(_iconForKind(item.kind), color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.bold(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _upcomingMeta(item),
                    style: AppFonts.semiBold(color: color, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Every section header shares one height so headers with and without
  // "See all" sit the same distance from the content around them.
  Widget _sectionHeader(String title, VoidCallback? onMore) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppFonts.extraBold(
                color: AppTheme.textPrimary,
                fontSize: 18,
              ),
            ),
          ),
          if (onMore != null)
            TextButton(
              onPressed: onMore,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(44, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('See all'),
            ),
        ],
      ),
    );
  }

  Widget _mediaFallback() {
    return Container(
      color: AppTheme.primaryDeep,
      alignment: Alignment.center,
      child: const Icon(Icons.play_lesson_outlined, color: Colors.white),
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
    MaterialPageRoute(builder: (_) => const SubjectListScreen()),
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

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }
}

class _Action {
  const _Action(this.icon, this.label, this.onTap, this.color);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
}
