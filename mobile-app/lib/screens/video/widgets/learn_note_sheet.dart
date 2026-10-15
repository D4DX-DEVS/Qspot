import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../services/video_progress_service.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../../../widgets/common/home_sheet_shell.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../model/video_model.dart';
import 'episode_close_button.dart';
import 'learn_content_list.dart';
import 'learn_note_empty.dart';

/// The "Learn — quick note" bottom popup: a short note about the episode and
/// its key points, both authored per video in the admin panel.
class LearnNoteSheet extends StatelessWidget {
  const LearnNoteSheet({super.key, required this.video});

  final VideoModel video;

  static Future<void> show(BuildContext context, VideoModel video) {
    VideoProgressService.recordNoteRead(video.id);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HomeSheetShell(child: LearnNoteSheet(video: video)),
    );
  }

  bool get _hasContent => video.hasLearnContent;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SoftIconTile(
                    icon: LucideIcons.lightbulb,
                    tone: p.amber,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Learn — Quick Note',
                          style: AppFonts.bold(color: p.text, fontSize: 16.5),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          video.displayTitle,
                          style: AppFonts.regular(
                            color: p.textMuted,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const EpisodeCloseButton(size: 38),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: _hasContent
                  ? LearnContentList(
                      video: video,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    )
                  : const SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: LearnNoteEmpty(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PressableScale(
                haptic: true,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.brand,
                      foregroundColor: p.card,
                      shape: const StadiumBorder(),
                      textStyle: AppFonts.bold(fontSize: 15),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Got It'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
