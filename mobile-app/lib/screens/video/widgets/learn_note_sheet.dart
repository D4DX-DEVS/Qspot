import 'package:flutter/material.dart';

import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../model/video_model.dart';
import '../../../services/video_progress_service.dart';

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
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => LearnNoteSheet(video: video),
    );
  }

  bool get _hasNote => video.learnText.trim().isNotEmpty;
  bool get _hasPoints => video.learnPoints.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.78;

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
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: AppTheme.primarySoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lightbulb_outline,
                                size: 15,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Learn — quick note',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.bold(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          video.displayTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.regular(
                            color: AppTheme.textMuted,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppTheme.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: _hasNote || _hasPoints ? _content() : _empty(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                    textStyle: AppFonts.bold(fontSize: 15),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasNote)
          Text(
            video.learnText,
            style: AppFonts.regular(
              color: AppTheme.textPrimary,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        if (_hasPoints) ...[
          if (_hasNote) const SizedBox(height: 20),
          Text(
            'KEY POINTS',
            style: AppFonts.bold(
              color: AppTheme.textMuted,
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
                      color: AppTheme.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 13,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point,
                      style: AppFonts.regular(
                        color: AppTheme.textPrimary,
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

  Widget _empty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        children: [
          Icon(Icons.lightbulb_outline, color: AppTheme.textMuted, size: 28),
          SizedBox(height: 10),
          Text(
            'This episode\'s quick note isn\'t ready yet.',
            textAlign: TextAlign.center,
            style: AppFonts.semiBold(
              color: AppTheme.textPrimary,
              fontSize: 14.5,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'The note written for this video will appear here.',
            textAlign: TextAlign.center,
            style: AppFonts.regular(
              color: AppTheme.textMuted,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
