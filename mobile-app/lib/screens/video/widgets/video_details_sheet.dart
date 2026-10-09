import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/home_sheet_shell.dart';
import '../model/video_model.dart';
import '../provider/video_details_sheet_provider.dart';
import 'episode_close_button.dart';
import 'episode_downloads_tab.dart';
import 'episode_learn_tab.dart';
import 'episode_practice_tab.dart';

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
      backgroundColor: Colors.transparent,
      builder: (context) => HomeSheetShell(
        child: VideoDetailsSheet(video: video, initialTab: initialTab),
      ),
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
      child: _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    final p = HomePalette.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: EpisodeCloseButton(),
                  ),
                  Text(
                    'Episode Details',
                    style: AppFonts.bold(color: p.text, fontSize: 17),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.video.displayTitle,
                textAlign: TextAlign.center,
                style: AppFonts.regular(
                  color: p.textMuted,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabs,
              labelColor: p.brand,
              unselectedLabelColor: p.textMuted,
              indicatorColor: p.brand,
              dividerColor: p.cardBorder,
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
                children: [
                  EpisodeLearnTab(video: widget.video),
                  EpisodeDownloadsTab(video: widget.video),
                  EpisodePracticeTab(video: widget.video),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
