import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../services/today_service.dart';
import '../../../themes/accent_tone.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/nav_list_card.dart';
import '../../../widgets/common/section_header.dart';
import '../model/today_item_text.dart';
import '../model/today_section.dart';

/// One block of the learner's work on Today: overdue, to do or coming up.
/// Shows the first few [items] as tappable cards, each with its own status
/// line, and an optional "See All" link.
class TodayTaskSection extends StatelessWidget {
  const TodayTaskSection({
    super.key,
    required this.section,
    required this.items,
    required this.onItemTap,
    this.onSeeAll,
    this.maxItems = 4,
  });

  /// [TodaySection.attention], [TodaySection.todo] or
  /// [TodaySection.comingUp]; anything else is shown as "Coming Up".
  final TodaySection section;
  final List<TodayLearningItem> items;
  final ValueChanged<TodayLearningItem> onItemTap;
  final VoidCallback? onSeeAll;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final palette = HomePalette.of(context);
    final (emoji, title, subtitle) = _copy;
    final tone = _tone(palette);
    final now = DateTime.now();
    final shown = items.take(maxItems).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        SectionHeader(
          emoji: emoji,
          title: title,
          subtitle: subtitle,
          actionLabel: onSeeAll == null ? null : 'See All',
          onAction: onSeeAll,
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _card(shown[i], palette, tone, now),
        ],
      ],
    );
  }

  Widget _card(
    TodayLearningItem item,
    HomePalette palette,
    AccentTone tone,
    DateTime now,
  ) {
    // Anything past due stands out, whichever block it sits in.
    final cardTone = item.status == 'overdue' ? palette.coral : tone;
    return NavListCard(
      icon: _iconFor(item.kind),
      tone: cardTone,
      title: item.title,
      subtitle: item.metaText(now),
      subtitleColor: section == TodaySection.comingUp ? null : cardTone.color,
      onTap: () => onItemTap(item),
    );
  }

  (String, String, String?) get _copy => switch (section) {
    TodaySection.attention => (
      '🚨',
      'Needs Your Attention',
      'Past Due. Sort These Out First!',
    ),
    TodaySection.todo => ('📝', 'Your To-Do List', null),
    _ => ('⏰', 'Coming Up', null),
  };

  AccentTone _tone(HomePalette palette) => switch (section) {
    TodaySection.attention => palette.coral,
    TodaySection.todo => palette.rose,
    _ => palette.teal,
  };

  static IconData _iconFor(String kind) {
    switch (kind) {
      case 'assignment':
        return LucideIcons.clipboardList;
      case 'quiz':
        return LucideIcons.pencilLine;
      case 'schedule':
        return LucideIcons.video;
      default:
        return LucideIcons.monitorPlay;
    }
  }
}
