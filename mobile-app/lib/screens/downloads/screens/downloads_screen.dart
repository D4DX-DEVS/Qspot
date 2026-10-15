import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/home_palette.dart';
import '../../../utils/byte_size.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/state_message_view.dart';
import '../../common/widgets/home_theme_scope.dart';
import '../../lesson/screens/lesson_screen.dart';
import '../../video/provider/video_provider.dart';
import '../provider/downloads_provider.dart';
import '../widgets/offline_lesson_tile.dart';

/// Lessons saved on this phone, how much space they use, and removing them.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeThemeScope(child: Builder(builder: _buildPage));
  }

  Widget _buildPage(BuildContext context) {
    final downloads = context.watch<DownloadsProvider>();
    final lessons = downloads.lessons;
    final p = HomePalette.of(context);
    return Scaffold(
      appBar: const CommonAppBar(title: 'Downloads'),
      body: lessons.isEmpty
          ? const StateMessageView(
              icon: LucideIcons.download,
              title: 'Nothing Saved Yet',
              message:
                  'Open a lesson and tap "Save for offline" to watch it '
                  'without internet.',
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                AppTheme.contentInset,
                8,
                AppTheme.contentInset,
                28 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                Text(
                  '${lessons.length} lesson${lessons.length == 1 ? '' : 's'} · '
                  '${byteSize(downloads.totalBytes)} on this phone',
                  style: AppFonts.medium(color: p.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                for (final lesson in lessons) ...[
                  OfflineLessonTile(
                    lesson: lesson,
                    onRemove: () => downloads.remove(lesson.lessonId),
                    onTap: () => _openLesson(context, lesson.lessonId),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _confirmRemoveAll(context, downloads),
                    icon: Icon(LucideIcons.trash2, color: p.error),
                    label: Text(
                      'Remove all downloads',
                      style: AppFonts.semiBold(color: p.error),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _openLesson(BuildContext context, String lessonId) {
    final video = context.read<VideoProvider>().getVideoById(lessonId);
    if (video == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeThemeScope(child: LessonScreen(video: video)),
      ),
    );
  }

  Future<void> _confirmRemoveAll(
    BuildContext context,
    DownloadsProvider downloads,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove All Downloads?'),
        content: const Text(
          'Saved lessons will need internet again. You can save them again '
          'at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Them'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove All'),
          ),
        ],
      ),
    );
    if (confirmed == true) await downloads.removeAll();
  }
}
