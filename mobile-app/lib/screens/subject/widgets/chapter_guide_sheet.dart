import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../services/video_progress_service.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../../../widgets/animation/staggered_entrance.dart';
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
        return LucideIcons.circlePlay;
      case 'quiz':
        return LucideIcons.listChecks;
      case 'question':
        return LucideIcons.messagesSquare;
      case 'schedule':
        return LucideIcons.calendarDays;
      case 'progress':
        return LucideIcons.trendingUp;
      case 'note':
        return LucideIcons.fileText;
      default:
        return LucideIcons.info;
    }
  }

  /// Shows the guide as a sheet. Returns when the student dismisses it.
  static Future<void> show(BuildContext context, SubjectModel subject) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: HomePalette.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ChapterGuideSheet(subject: subject),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
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
            StaggeredEntrance(
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: subject.imageUrl == null
                      ? Container(
                          width: 104,
                          height: 104,
                          color: p.brandSoft,
                          alignment: Alignment.center,
                          child: Icon(
                            LucideIcons.bookOpen,
                            color: p.brand,
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
                            color: p.brandSoft,
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 104,
                            height: 104,
                            color: p.brandSoft,
                            alignment: Alignment.center,
                            child: Icon(
                              LucideIcons.bookOpen,
                              color: p.brand,
                              size: 34,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            StaggeredEntrance(
              index: 1,
              child: Text(
                subject.guideTitle.isEmpty
                    ? SubjectModel.defaultGuideTitle
                    : subject.guideTitle,
                textAlign: TextAlign.center,
                style: AppFonts.bold(color: p.text, fontSize: 22, height: 1.25),
              ),
            ),
            const SizedBox(height: 6),
            StaggeredEntrance(
              index: 1,
              child: Text(
                subject.subject,
                textAlign: TextAlign.center,
                style: AppFonts.regular(color: p.textMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            ...points.indexed.map(
              (entry) => StaggeredEntrance(
                index: entry.$1 + 2,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: p.brandSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          iconFor(entry.$2.icon),
                          color: p.brand,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            entry.$2.text,
                            style: AppFonts.regular(
                              color: p.text,
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
            ),
            const SizedBox(height: 12),
            StaggeredEntrance(
              index: points.length + 2,
              child: PressableScale(
                haptic: true,
                child: SizedBox(
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.brand,
                      foregroundColor: AppColors.onPrimary,
                      shape: const StadiumBorder(),
                      textStyle: AppFonts.bold(fontSize: 16),
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
