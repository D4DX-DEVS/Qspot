import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../services/video_progress_service.dart';
import '../../../themes/app_theme.dart';
import '../model/subject_model.dart';

/// The panel shown the first time a chapter is opened: what the chapter
/// contains, and a single "Got it" action to dismiss it.
///
/// The "seen" flag lives server-side (`/api/user/prefs.seenGuides`, R9) so it
/// follows the account across devices instead of being per-device.
class ChapterGuideSheet extends StatelessWidget {
  const ChapterGuideSheet({super.key, required this.subject});

  final SubjectModel subject;

  // Cached for the app session so repeated chapter opens don't each hit the
  // network just to check "have I seen this one".
  static UserPrefs? _cachedPrefs;

  static Future<UserPrefs> _prefs() async {
    return _cachedPrefs ??= await VideoProgressService.fetchPrefs();
  }

  /// True when this chapter's guide has not been shown on this account yet.
  static Future<bool> shouldShow(String subjectId) async {
    final prefs = await _prefs();
    return !prefs.seenGuides.contains(subjectId);
  }

  static Future<void> markSeen(String subjectId) async {
    final prefs = await _prefs();
    if (prefs.seenGuides.contains(subjectId)) return;
    final updated = [...prefs.seenGuides, subjectId];
    _cachedPrefs = await VideoProgressService.updatePrefs(seenGuides: updated);
  }

  static IconData iconFor(String icon) {
    switch (icon) {
      case 'video':
        return Icons.play_circle_fill;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'question':
        return Icons.forum_outlined;
      case 'schedule':
        return Icons.calendar_month_outlined;
      case 'progress':
        return Icons.trending_up;
      case 'note':
        return Icons.description_outlined;
      default:
        return Icons.info_outline;
    }
  }

  /// Shows the guide as a sheet. Returns when the student dismisses it.
  static Future<void> show(BuildContext context, SubjectModel subject) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ChapterGuideSheet(subject: subject),
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = subject.guidePoints.isEmpty
        ? SubjectModel.defaultGuidePoints
        : subject.guidePoints;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The chapter's own cover art, so the panel feels like part of it.
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: subject.imageUrl == null
                    ? Container(
                        width: 104,
                        height: 104,
                        color: AppTheme.primarySoft,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.menu_book,
                          color: AppTheme.primary,
                          size: 34,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: subject.imageUrl!,
                        width: 104,
                        height: 104,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 104,
                          height: 104,
                          color: AppTheme.surfaceAlt,
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 104,
                          height: 104,
                          color: AppTheme.primarySoft,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.menu_book,
                            color: AppTheme.primary,
                            size: 34,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              subject.guideTitle.isEmpty
                  ? SubjectModel.defaultGuideTitle
                  : subject.guideTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subject.subject,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ...points.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        iconFor(point.icon),
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          point.text,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.onPrimary,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
