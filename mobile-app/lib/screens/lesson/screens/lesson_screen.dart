import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../bookmark/provider/bookmark_provider.dart';
import '../../common/widgets/home_theme_scope.dart';
import '../../course/model/syllabus_lesson.dart';
import '../../subject/provider/subject_provider.dart';
import '../../video/model/video_model.dart';
import '../../video/provider/video_provider.dart';
import '../../video/screens/video_player_screen.dart';
import '../../video/screens/video_questions_screen.dart';
import '../model/lesson_tab.dart';
import '../provider/lesson_screen_provider.dart';
import '../widgets/lesson_downloads_panel.dart';
import '../widgets/lesson_learn_panel.dart';
import '../widgets/lesson_list_sheet.dart';
import '../widgets/lesson_nav_bar.dart';
import '../widgets/lesson_player_card.dart';
import '../widgets/lesson_practice_panel.dart';
import '../widgets/lesson_tab_bar.dart';
import '../widgets/lesson_title_block.dart';
import '../../../services/telemetry/telemetry.dart';
import '../../downloads/widgets/lesson_offline_button.dart';

/// One lesson: where it sits in its course, a button to play it, its notes,
/// downloads and practice, and buttons to move to the lesson before or after.
/// A lesson that has not been released yet cannot be played.
class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key, required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        Telemetry.event('lesson_opened', {'video_id': video.id});
        return LessonScreenProvider.forApp(
          video: video,
          videos: context.read<VideoProvider>(),
          subjects: context.read<SubjectProvider>(),
          bookmarks: context.read<BookmarkProvider>(),
        );
      },
      child: Consumer<LessonScreenProvider>(
        builder: (context, state, _) => _buildPage(context, state),
      ),
    );
  }

  Widget _buildPage(BuildContext context, LessonScreenProvider state) {
    return Scaffold(
      appBar: CommonAppBar(
        titleWidget: _appBarTitle(context, state),
        actions: [
          IconButton(
            tooltip: state.isSaved ? 'Remove from bookmarks' : 'Save lesson',
            onPressed: () => _toggleSaved(context, state),
            icon: Icon(
              state.isSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: 24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          LessonPlayerCard(
            thumbnailUrl: video.thumbnailUrl,
            label: state.playLabel,
            fraction: state.watchedFraction,
            positionText: state.positionText,
            durationText: state.durationText,
            enabled: state.canPlay,
            onTap: () => _play(context, state),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LessonTitleBlock(
                  title: video.displayTitle,
                  subtitle: state.subtitle,
                  positionLabel: state.positionLabel,
                ),
                const SizedBox(height: 12),
                LessonOfflineButton(video: video),
                const SizedBox(height: 14),
                LessonTabBar(
                  selected: state.tab,
                  onSelected: state.selectTab,
                  practiceLocked:
                      !state.practiceUnlocked && state.questionCount > 0,
                ),
                const SizedBox(height: 16),
                _panel(context, state),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: LessonNavBar(
        hasPrevious: state.previous != null,
        hasNext: state.next != null,
        canOpenNext: state.canOpenNext,
        nextHint: state.nextHint,
        onPrevious: () => _open(context, state.previous!),
        onLessons: () => _showLessons(context, state),
        onNext: () => _open(context, state.next!),
      ),
    );
  }

  Widget _appBarTitle(BuildContext context, LessonScreenProvider state) {
    final palette = HomePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.crumb.isNotEmpty)
          Text(
            state.crumb,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.regular(color: palette.textMuted, fontSize: 12),
          ),
        Text(
          state.chapterTitle.isEmpty ? 'Lesson' : state.chapterTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.semiBold(color: palette.text, fontSize: 16),
        ),
      ],
    );
  }

  Widget _panel(BuildContext context, LessonScreenProvider state) =>
      switch (state.tab) {
        LessonTab.learn => LessonLearnPanel(video: video),
        LessonTab.downloads => LessonDownloadsPanel(video: video),
        LessonTab.practice => LessonPracticePanel(
          questionCount: state.questionCount,
          unlocked: state.practiceUnlocked,
          onStart: () => VideoQuestionsScreen.open(context, video),
        ),
      };

  Future<void> _play(BuildContext context, LessonScreenProvider state) async {
    if (!state.canPlay) {
      _tell(context, state.playBlockedMessage ?? 'This lesson is not open.');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
    );
    // A lesson finished in the player shows as done and opens Practice.
    await state.refreshProgress();
  }

  /// Moves to another lesson, replacing this page so Back goes to the list.
  void _open(BuildContext context, SyllabusLesson lesson) {
    if (!lesson.isOpenable) {
      _tell(context, lesson.blockedMessage ?? 'This lesson is not open.');
      return;
    }
    if (lesson.id == video.id) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HomeThemeScope(child: LessonScreen(video: lesson.video)),
      ),
    );
  }

  void _showLessons(BuildContext context, LessonScreenProvider state) {
    LessonListSheet.show(
      context,
      syllabus: state.syllabus,
      currentId: video.id,
      onSelect: (lesson) => _open(context, lesson),
    );
  }

  Future<void> _toggleSaved(
    BuildContext context,
    LessonScreenProvider state,
  ) async {
    final saved = await state.toggleSaved();
    if (saved == null || !context.mounted) return;
    AppSnackBar.show(
      context,
      message: saved
          ? 'Saved to your bookmarks'
          : 'Removed from your bookmarks',
      color: AppColors.success,
      duration: const Duration(seconds: 2),
    );
  }

  void _tell(BuildContext context, String message) => AppSnackBar.show(
    context,
    message: message,
    color: AppColors.warningOrange,
  );
}
