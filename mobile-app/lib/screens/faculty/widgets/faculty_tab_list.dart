import 'package:flutter/material.dart';

import '../../../themes/app_theme.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/state_message_view.dart';

/// One tab of the faculty workspace: a section header, then the cards, or an
/// empty message when there are none. Pull down to refresh. On wide screens
/// the column stays at a readable width in the middle.
class FacultyTabList extends StatelessWidget {
  const FacultyTabList({
    super.key,
    required this.title,
    this.subtitle,
    required this.itemCount,
    required this.itemBuilder,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onRefresh,
  });

  final String title;
  final String? subtitle;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  static const double _maxWidth = 720;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: p.card,
      color: p.brand,
      child: LayoutBuilder(
        builder: (context, box) {
          final side = box.maxWidth > _maxWidth + AppTheme.contentInset * 2
              ? (box.maxWidth - _maxWidth) / 2
              : AppTheme.contentInset;
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              side,
              AppTheme.contentInset,
              side,
              28 + MediaQuery.paddingOf(context).bottom,
            ),
            itemCount: itemCount == 0 ? 2 : itemCount + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SectionHeader(title: title, subtitle: subtitle),
                );
              }
              if (itemCount == 0) {
                return SizedBox(
                  height: box.maxHeight * 0.6,
                  child: StateMessageView(
                    icon: emptyIcon,
                    title: emptyTitle,
                    message: emptyMessage,
                  ),
                );
              }
              return StaggeredEntrance(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: itemBuilder(context, index - 1),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
