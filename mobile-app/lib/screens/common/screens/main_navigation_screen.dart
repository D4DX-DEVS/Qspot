import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../home/screens/redesigned_home_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../progress/screens/progress_screen.dart';
import '../../subject/screens/subject_list_screen.dart';
import '../../practice/screens/practice_hub_screen.dart';
import '../../../widgets/common/floating_nav_bar.dart';
import '../../../widgets/common/floating_nav_bar_item.dart';
import '../provider/main_navigation_provider.dart';
import '../widgets/home_theme_scope.dart';

/// Primary learner shell for the daily learning loop.
class MainNavigationScreen extends StatefulWidget {
  final int? currentIndex;

  const MainNavigationScreen({super.key, this.currentIndex});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final MainNavigationProvider _nav;

  static const _screens = <Widget>[
    RedesignedHomeScreen(),
    SubjectListScreen(),
    PracticeHubScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _nav = MainNavigationProvider(
      tabCount: _screens.length,
      initialIndex: widget.currentIndex ?? 0,
    );
  }

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != null &&
        widget.currentIndex != _nav.currentIndex) {
      _nav.setIndex(widget.currentIndex!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _nav,
      child: Consumer<MainNavigationProvider>(
        builder: (_, nav, __) => _buildPage(nav),
      ),
    );
  }

  Widget _buildPage(MainNavigationProvider nav) {
    return HomeThemeScope(
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: nav.currentIndex, children: _screens),
        bottomNavigationBar: _bottomBar(nav),
      ),
    );
  }

  Widget _bottomBar(MainNavigationProvider nav) {
    return FloatingNavBar(
      currentIndex: nav.currentIndex,
      onTap: nav.setIndex,
      items: const [
        FloatingNavBarItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Today',
        ),
        FloatingNavBarItem(
          icon: Icons.menu_book_outlined,
          activeIcon: Icons.menu_book,
          label: 'Learn',
        ),
        FloatingNavBarItem(
          icon: Icons.edit_note_outlined,
          activeIcon: Icons.edit_note,
          label: 'Practice',
        ),
        FloatingNavBarItem(
          icon: Icons.insights_outlined,
          activeIcon: Icons.insights,
          label: 'Progress',
        ),
        FloatingNavBarItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Me',
        ),
      ],
    );
  }
}
