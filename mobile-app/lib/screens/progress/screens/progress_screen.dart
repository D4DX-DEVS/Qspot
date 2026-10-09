import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../services/learning_progress_service.dart';
import '../../../themes/accent_tone.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/info_note_card.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/stat_tile.dart';
import '../../../widgets/common/surface_card.dart';
import '../../video/provider/video_provider.dart';
import '../provider/progress_screen_provider.dart';
import '../widgets/activity_tile.dart';
import '../widgets/mastery_progress_row.dart';
import '../widgets/mastery_ring_card.dart';
import '../widgets/progress_unavailable_view.dart';

typedef ProgressLoader = Future<LearningProgressData> Function();

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, this.loadData});

  final ProgressLoader? loadData;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late final ProgressScreenProvider _progress;

  @override
  void initState() {
    super.initState();
    _progress = ProgressScreenProvider(
      widget.loadData ?? LearningProgressService.fetch,
    );
    _load();
  }

  Future<void> _load() async {
    await _progress.load();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _progress,
      child: Consumer<ProgressScreenProvider>(
        builder: (_, progress, __) => _buildPage(progress),
      ),
    );
  }

  Widget _buildPage(ProgressScreenProvider progress) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Progress', isDrawerNeeded: true),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(progress)),
    );
  }

  Widget _buildBody(ProgressScreenProvider progress) {
    if (progress.loading && progress.data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 260),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    final data = progress.data;
    if (data == null) {
      return ProgressUnavailableView(
        onRetry: _load,
        message: progress.errorMessage,
      );
    }

    final palette = HomePalette.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        const StaggeredEntrance(
          child: SectionHeader(
            title: 'Your Learning, in View',
            subtitle:
                'Notice what is becoming familiar and choose your next step.',
          ),
        ),
        const SizedBox(height: 16),
        StaggeredEntrance(index: 1, child: _statsBand(data, palette)),
        const SizedBox(height: 22),
        const StaggeredEntrance(
          index: 2,
          child: SectionHeader(title: 'Mastery'),
        ),
        const SizedBox(height: 8),
        StaggeredEntrance(
          index: 2,
          child: MasteryRingCard(
            percent: data.masteryPercent,
            title: 'Lesson Mastery',
            detail: data.videosTotal == 0
                ? 'Start Your First Lesson'
                : '${data.videosCompleted} of ${data.videosTotal} started lessons complete',
            highlight: data.videosInProgress > 0
                ? '${data.videosInProgress} In Progress'
                : null,
            highlightColor: palette.coral.color,
          ),
        ),
        if (data.courses.isNotEmpty) ...[
          const SizedBox(height: 22),
          StaggeredEntrance(
            index: 3,
            child: _masteryGroup('Courses', data.courses),
          ),
        ],
        if (data.subjects.isNotEmpty) ...[
          const SizedBox(height: 22),
          StaggeredEntrance(
            index: 4,
            child: _masteryGroup('Chapters', data.subjects),
          ),
        ],
        const SizedBox(height: 22),
        const StaggeredEntrance(
          index: 5,
          child: SectionHeader(title: 'Recent Activity'),
        ),
        const SizedBox(height: 8),
        ..._recentActivity(data, palette),
      ],
    );
  }

  Widget _statsBand(LearningProgressData data, HomePalette palette) {
    final stats = data.stats;
    final tiles = [
      StatTile(
        icon: LucideIcons.flame,
        color: palette.coral.color,
        value: '${stats?.currentStreak ?? 0}',
        label: 'Day Streak',
      ),
      StatTile(
        icon: LucideIcons.medal,
        color: palette.rose.color,
        value: '${stats?.level ?? 1}',
        label: 'Level',
      ),
      StatTile(
        icon: LucideIcons.zap,
        color: palette.amber.color,
        value: '${stats?.xp ?? 0}',
        label: 'XP',
      ),
    ];
    // Tiles share the tallest one's height when a label wraps.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }

  Widget _masteryGroup(String title, List<MasteryItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: 8),
        SurfaceCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
          child: Column(
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: MasteryProgressRow(
                    title: item.title,
                    completed: item.completed,
                    total: item.total,
                    percent: item.percent,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _recentActivity(LearningProgressData data, HomePalette palette) {
    final activities =
        <_ActivityRowData>[
          ...data.activities.map(
            (item) => _ActivityRowData(
              kind: item.isVideoQuiz ? 'Video Quiz' : 'Quiz',
              title: item.title,
              detail:
                  '${item.score}/${item.totalQuestions} correct - ${item.percentage.round()}%',
              date: item.createdAt,
              icon: item.isVideoQuiz
                  ? LucideIcons.monitorPlay
                  : LucideIcons.pencilLine,
              tone: item.isVideoQuiz ? palette.coral : palette.rose,
            ),
          ),
          ..._lessonActivity(palette),
        ]..sort((a, b) {
          final aDate = a.date;
          final bDate = b.date;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

    if (activities.isEmpty) {
      return [
        InfoNoteCard(
          icon: LucideIcons.activity,
          tone: palette.slate,
          message: 'Your completed lessons and assessments will appear here.',
        ),
      ];
    }

    return activities
        .take(8)
        .indexed
        .map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: StaggeredEntrance(
              index: entry.$1,
              child: ActivityTile(
                icon: entry.$2.icon,
                tone: entry.$2.tone,
                kind: entry.$2.kind,
                title: entry.$2.title,
                detail: entry.$2.detail,
                dateLabel: entry.$2.date == null
                    ? null
                    : _dateLabel(entry.$2.date!),
              ),
            ),
          ),
        )
        .toList();
  }

  List<_ActivityRowData> _lessonActivity(HomePalette palette) {
    final videos = context.read<VideoProvider>();
    return videos.progressByVideo.entries
        .map((entry) {
          final title =
              videos.getVideoById(entry.key)?.displayTitle ?? 'Lesson';
          final progress = entry.value;
          return _ActivityRowData(
            kind: progress.completed ? 'Lesson Complete' : 'Lesson',
            title: title,
            detail: progress.completed ? 'Completed' : 'Viewed',
            date: progress.completedAt ?? progress.lastViewedAt,
            icon: progress.completed
                ? LucideIcons.circleCheck
                : LucideIcons.circlePlay,
            tone: progress.completed ? palette.mint : palette.coral,
          );
        })
        .where((item) => item.date != null)
        .toList();
  }

  String _dateLabel(DateTime date) {
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _ActivityRowData {
  const _ActivityRowData({
    required this.kind,
    required this.title,
    required this.detail,
    required this.icon,
    required this.tone,
    this.date,
  });

  final String kind;
  final String title;
  final String detail;
  final IconData icon;
  final AccentTone tone;
  final DateTime? date;
}
