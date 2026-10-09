import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app_bar_title.dart';
import 'app_drawer.dart';

/// App-wide top bar. Colours, elevation and title style come from the active
/// theme's `appBarTheme`, so screens only pass content.
///
/// Use [title] for plain text; pass [titleWidget] instead when the bar needs
/// custom content (e.g. a search field). [titleWidget] wins when both are set.
///
/// Set [isDrawerNeeded] to show a menu button that opens the [AppDrawer] on a
/// root destination. When the same screen is pushed as a child route, the
/// normal back arrow takes priority so every destination remains escapable.
///
/// [backgroundColor] and [elevation] override the theme for bars that sit over
/// artwork (e.g. a transparent bar with no shadow); null keeps the theme's.
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.centerTitle = false,
    this.bottom,
    this.isDrawerNeeded = false,
    this.backgroundColor,
    this.elevation,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final bool isDrawerNeeded;
  final Color? backgroundColor;
  final double? elevation;

  /// Space kept below the bar (inside it, so the shadow sits under the gap).
  static const double bottomPadding = 8;

  /// Height of a bar without a [bottom].
  static const double baseHeight = kToolbarHeight + bottomPadding;

  @override
  Size get preferredSize =>
      Size.fromHeight(baseHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final showDrawer = isDrawerNeeded && !Navigator.of(context).canPop();
    return AppBar(
      title:
          titleWidget ??
          (title == null ? null : AppBarTitle(title!, centered: centerTitle)),
      leading:
          leading ??
          (showDrawer
              ? IconButton(
                  icon: const Icon(LucideIcons.menu),
                  tooltip: 'Menu',
                  onPressed: () => showAppDrawer(context),
                )
              : null),
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      elevation: elevation,
      scrolledUnderElevation: elevation,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(
          (bottom?.preferredSize.height ?? 0) + bottomPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?bottom,
            const SizedBox(height: bottomPadding),
          ],
        ),
      ),
    );
  }
}
