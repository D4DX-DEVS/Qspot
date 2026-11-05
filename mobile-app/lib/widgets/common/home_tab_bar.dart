import 'package:flutter/material.dart';

import '../../themes/app_fonts.dart';
import '../../themes/home_palette.dart';

/// Swipeable tabs for an app bar's `bottom`, in the home palette: burgundy
/// label and underline on the chosen tab, muted labels for the rest, the
/// same look as [UnderlineTabBar]. Needs a [TabController] above it, such as
/// a `DefaultTabController`.
class HomeTabBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeTabBar({super.key, required this.labels});

  final List<String> labels;

  @override
  Size get preferredSize => const Size.fromHeight(46);

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return TabBar(
      tabs: [for (final label in labels) Tab(text: label, height: 44)],
      labelColor: p.brand,
      unselectedLabelColor: p.textMuted,
      labelStyle: AppFonts.bold(color: p.brand, fontSize: 13),
      unselectedLabelStyle: AppFonts.semiBold(color: p.textMuted, fontSize: 13),
      indicatorColor: p.brand,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: p.cardBorder,
      overlayColor: WidgetStatePropertyAll(p.brandSoft),
    );
  }
}
