import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../services/navigation_config_service.dart';
import '../../home/screens/redesigned_home_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../progress/screens/progress_screen.dart';
import '../../subject/screens/subject_list_screen.dart';
import '../../practice/screens/practice_hub_screen.dart';
import '../../../widgets/animation/fade_on_change.dart';
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

  static const _allTabs = <_NavigationTab>[
    _NavigationTab(
      keyName: 'today',
      label: 'Today',
      icon: LucideIcons.house,
      activeIcon: LucideIcons.house,
      screen: RedesignedHomeScreen(),
    ),
    _NavigationTab(
      keyName: 'learn',
      label: 'Learn',
      icon: LucideIcons.bookOpen,
      activeIcon: LucideIcons.bookOpen,
      screen: SubjectListScreen(),
    ),
    _NavigationTab(
      keyName: 'practice',
      label: 'Practice',
      icon: LucideIcons.pencilLine,
      activeIcon: LucideIcons.pencilLine,
      screen: PracticeHubScreen(),
    ),
    _NavigationTab(
      keyName: 'progress',
      label: 'Progress',
      icon: LucideIcons.chartNoAxesCombined,
      activeIcon: LucideIcons.chartNoAxesCombined,
      screen: ProgressScreen(),
    ),
    _NavigationTab(
      keyName: 'me',
      label: 'Me',
      icon: LucideIcons.userRound,
      activeIcon: LucideIcons.userRound,
      screen: ProfileScreen(),
    ),
  ];

  late List<_NavigationTab> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = _allTabs;
    final initialIndex = widget.currentIndex ?? 0;
    _nav = MainNavigationProvider(
      tabCount: _tabs.length,
      initialIndex: initialIndex,
      tabKeys: _tabs.map((tab) => tab.keyName).toList(),
    );
    _loadNavigationConfig(initialIndex);
  }

  Future<void> _loadNavigationConfig(int requestedIndex) async {
    final requestedKey =
        _allTabs[requestedIndex.clamp(0, _allTabs.length - 1).toInt()].keyName;
    final config = await NavigationConfigService.fetchConfig();
    if (!mounted) return;
    final activeKeyBeforeApply = _nav.currentKey;

    final configuredKeys = config.items.map((item) => item.key).toSet();
    final tabs = <_NavigationTab>[];
    for (final item in config.items) {
      _NavigationTab? tab;
      for (final candidate in _allTabs) {
        if (candidate.keyName == item.key) {
          tab = candidate;
          break;
        }
      }
      if (tab != null && configuredKeys.contains(tab.keyName)) tabs.add(tab);
    }
    if (tabs.isEmpty) tabs.add(_allTabs.first);

    setState(() => _tabs = tabs);
    _nav.setTabConfiguration(
      tabCount: tabs.length,
      tabKeys: tabs.map((tab) => tab.keyName).toList(),
    );
    final targetKey = activeKeyBeforeApply ?? requestedKey;
    final configuredIndex = tabs.indexWhere((tab) => tab.keyName == targetKey);
    final todayIndex = tabs.indexWhere((tab) => tab.keyName == 'today');
    _nav.setIndex(
      configuredIndex < 0 ? (todayIndex < 0 ? 0 : todayIndex) : configuredIndex,
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
        body: FadeOnChange(
          trigger: nav.currentIndex,
          child: IndexedStack(
            index: nav.currentIndex,
            children: [
              for (final tab in _tabs)
                TickerMode(
                  enabled: tab.keyName == nav.currentKey,
                  child: KeyedSubtree(
                    key: ValueKey(tab.keyName),
                    child: tab.screen,
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: _bottomBar(nav),
      ),
    );
  }

  Widget _bottomBar(MainNavigationProvider nav) {
    return FloatingNavBar(
      currentIndex: nav.currentIndex,
      onTap: nav.setIndex,
      items: [
        for (final tab in _tabs)
          FloatingNavBarItem(
            icon: tab.icon,
            activeIcon: tab.activeIcon,
            label: tab.label,
          ),
      ],
    );
  }
}

class _NavigationTab {
  const _NavigationTab({
    required this.keyName,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.screen,
  });

  final String keyName;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;
}
