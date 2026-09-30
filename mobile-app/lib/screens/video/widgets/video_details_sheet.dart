import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../model/video_model.dart';
import '../provider/video_details_sheet_provider.dart';
import '../provider/video_provider.dart';
import '../screens/video_questions_screen.dart';

/// Everything attached to one episode, behind a small tab strip:
/// Learn (a short note), Downloads (handouts) and Practice (its questions).
class VideoDetailsSheet extends StatefulWidget {
  const VideoDetailsSheet({
    super.key,
    required this.video,
    this.initialTab = 0,
  });

  final VideoModel video;
  final int initialTab;

  static Future<void> show(
    BuildContext context,
    VideoModel video, {
    int initialTab = 0,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) =>
          VideoDetailsSheet(video: video, initialTab: initialTab),
    );
  }

  @override
  State<VideoDetailsSheet> createState() => _VideoDetailsSheetState();
}

class _VideoDetailsSheetState extends State<VideoDetailsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final VideoDetailsSheetProvider _details = VideoDetailsSheetProvider();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 3,
      initialIndex: widget.initialTab.clamp(0, 2),
      vsync: this,
    );
    _details.loadQuestions(widget.video.id);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _details,
      child: Consumer<VideoDetailsSheetProvider>(
        builder: (_, details, __) => _buildPage(details),
      ),
    );
  }

  Widget _buildPage(VideoDetailsSheetProvider details) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.72,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceAlt,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Episode details',
                    style: AppFonts.bold(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.video.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.regular(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabs,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: AppFonts.bold(fontSize: 14),
              unselectedLabelStyle: AppFonts.medium(fontSize: 14),
              tabs: const [
                Tab(text: 'Learn'),
                Tab(text: 'Downloads'),
                Tab(text: 'Practice'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [_learnTab(), _downloadsTab(), _practiceTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppFonts.regular(
            color: AppColors.textMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _learnTab() {
    final video = widget.video;
    if (video.learnText.isEmpty && video.learnPoints.isEmpty) {
      return _empty('No notes for this episode yet.');
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (video.learnText.isNotEmpty)
          Text(
            video.learnText,
            style: AppFonts.regular(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        if (video.learnPoints.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'KEY POINTS',
            style: AppFonts.bold(
              color: AppColors.textMuted,
              fontSize: 11.5,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          ...video.learnPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 13,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point,
                      style: AppFonts.regular(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _downloadsTab() {
    final downloads = widget.video.downloads;
    if (downloads.isEmpty) {
      return _empty('No downloads for this episode yet.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: downloads.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = downloads[index];
        return Material(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => launchUrl(
              Uri.parse(item.url),
              mode: LaunchMode.externalApplication,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.download_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.title,
                      style: AppFonts.semiBold(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.open_in_new,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _practiceTab() {
    if (_details.loadingQuestions) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_details.questions.isEmpty) {
      return _empty('No practice questions for this episode yet.');
    }

    final progress = context.watch<VideoProvider>().progressFor(
      widget.video.id,
    );
    final unlocked = progress?.completed == true;

    if (!unlocked) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: AppColors.textMuted,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '${_details.questions.length} question${_details.questions.length == 1 ? '' : 's'} '
                      'on this episode',
                      style: AppFonts.semiBold(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Finish watching to unlock the quiz.',
              style: AppFonts.regular(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.quiz_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '${_details.questions.length} question${_details.questions.length == 1 ? '' : 's'} '
                    'on this episode',
                    style: AppFonts.semiBold(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You finished this episode — try the questions below.',
            style: AppFonts.regular(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: const StadiumBorder(),
                textStyle: AppFonts.bold(fontSize: 16),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                VideoQuestionsScreen.open(context, widget.video);
              },
              child: const Text('Start practice'),
            ),
          ),
        ],
      ),
    );
  }
}
