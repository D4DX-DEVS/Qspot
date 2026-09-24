import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/learning_progress_service.dart';
import '../../../themes/app_theme.dart';
import '../../video/provider/video_provider.dart';

typedef ProgressLoader = Future<LearningProgressData> Function();

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, this.loadData});

  final ProgressLoader? loadData;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late final ProgressLoader _loadData;
  LearningProgressData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData = widget.loadData ?? LearningProgressService.fetch;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final data = await _loadData();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Progress')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 260),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    final data = _data;
    if (data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          const SizedBox(height: 140),
          const Icon(
            Icons.insights_outlined,
            size: 44,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 14),
          Text(
            'Progress is unavailable',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const Text('Your learning, in view', style: AppTheme.sectionTitle),
        const SizedBox(height: 5),
        const Text(
          'Notice what is becoming familiar and choose your next step.',
          style: AppTheme.sectionIntro,
        ),
        const SizedBox(height: 18),
        _statsBand(data),
        const SizedBox(height: 24),
        _sectionTitle('Mastery'),
        const SizedBox(height: 12),
        _overallMastery(data),
        if (data.courses.isNotEmpty) ...[
          const SizedBox(height: 24),
          _masteryGroup('Courses', data.courses),
        ],
        if (data.subjects.isNotEmpty) ...[
          const SizedBox(height: 24),
          _masteryGroup('Chapters', data.subjects),
        ],
        const SizedBox(height: 28),
        _sectionTitle('Recent activity'),
        const SizedBox(height: 12),
        ..._recentActivity(data),
      ],
    );
  }

  Widget _statsBand(LearningProgressData data) {
    final stats = data.stats;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _stat(
            Icons.local_fire_department_outlined,
            '${stats?.currentStreak ?? 0}',
            'day streak',
            AppTheme.accent,
          ),
          _stat(
            Icons.military_tech_outlined,
            '${stats?.level ?? 1}',
            'level',
            AppTheme.primary,
          ),
          _stat(
            Icons.bolt_outlined,
            '${stats?.xp ?? 0}',
            'XP',
            AppTheme.warning,
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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

  Widget _sectionTitle(String text) {
    return Text(text, style: AppTheme.sectionTitle);
  }

  Widget _overallMastery(LearningProgressData data) {
    final percent = data.masteryPercent;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.surfaceAlt,
                  color: AppTheme.primary,
                ),
                Center(
                  child: Text(
                    '${(percent * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lesson mastery',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  data.videosTotal == 0
                      ? 'Start your first lesson'
                      : '${data.videosCompleted} of ${data.videosTotal} started lessons complete',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                if (data.videosInProgress > 0) ...[
                  const SizedBox(height: 7),
                  Text(
                    '${data.videosInProgress} in progress',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _masteryGroup(String title, List<MasteryItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...items.map(_masteryRow),
      ],
    );
  }

  Widget _masteryRow(MasteryItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${item.completed}/${item.total}',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.percent,
              minHeight: 6,
              backgroundColor: AppTheme.surfaceAlt,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _recentActivity(LearningProgressData data) {
    final activities =
        <_ActivityRowData>[
          ...data.activities.map(
            (item) => _ActivityRowData(
              kind: item.isVideoQuiz ? 'Video quiz' : 'Quiz',
              title: item.title,
              detail:
                  '${item.score}/${item.totalQuestions} correct - ${item.percentage.round()}%',
              date: item.createdAt,
              icon: item.isVideoQuiz
                  ? Icons.play_lesson_outlined
                  : Icons.edit_note_outlined,
              color: item.isVideoQuiz ? AppTheme.accent : AppTheme.primary,
            ),
          ),
          ..._lessonActivity(),
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
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.timeline_outlined, color: AppTheme.textMuted),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your completed lessons and assessments will appear here.',
                  style: TextStyle(color: AppTheme.textMuted, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return activities.take(8).map(_activityRow).toList();
  }

  List<_ActivityRowData> _lessonActivity() {
    final videos = context.read<VideoProvider>();
    return videos.progressByVideo.entries
        .map((entry) {
          final title =
              videos.getVideoById(entry.key)?.displayTitle ?? 'Lesson';
          final progress = entry.value;
          return _ActivityRowData(
            kind: progress.completed ? 'Lesson complete' : 'Lesson',
            title: title,
            detail: progress.completed ? 'Completed' : 'Viewed',
            date: progress.completedAt ?? progress.lastViewedAt,
            icon: progress.completed
                ? Icons.check_circle_outline
                : Icons.play_circle_outline,
            color: progress.completed ? AppTheme.success : AppTheme.accent,
          );
        })
        .where((item) => item.date != null)
        .toList();
  }

  Widget _activityRow(_ActivityRowData item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.kind,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.detail,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (item.date != null)
              Text(
                _dateLabel(item.date!),
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10.5,
                ),
              ),
          ],
        ),
      ),
    );
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
    required this.color,
    this.date,
  });

  final String kind;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final DateTime? date;
}
