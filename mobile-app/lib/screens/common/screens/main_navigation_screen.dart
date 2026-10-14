import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../services/navigation_config_service.dart';
import '../../../services/session_renewal_service.dart';
import '../../banner/provider/banner_provider.dart';
import '../../bookmark/provider/bookmark_provider.dart';
import '../../home/screens/redesigned_home_screen.dart';
import '../../notification/provider/notification_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../progress/screens/progress_screen.dart';
import '../../quiz/provider/quiz_provider.dart';
import '../../speaker/provider/speaker_provider.dart';
import '../../subject/provider/subject_provider.dart';
import '../../subject/screens/subject_list_screen.dart';
import '../../practice/screens/practice_hub_screen.dart';
import '../../video/provider/video_provider.dart';
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
  late final AppLifecycleListener _lifecycle;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSharedData());
    _lifecycle = AppLifecycleListener(onResume: _onAppResumed);
  }

  /// Back in front: renew a sign-in about to run out, and send quiz answers
  /// still on the phone (e.g. a quiz that closed while the app was away).
  void _onAppResumed() {
    if (!mounted) return;
    unawaited(SessionRenewalService.renewIfNeeded());
    unawaited(context.read<QuizProvider>().flushPendingSubmissions());
  }

  /// Starts the lists several tabs read, so no single tab has to be the one
  /// that loads them. Each provider reports its own errors.
  void _startSharedData() {
    if (!mounted) return;
    unawaited(SessionRenewalService.renewIfNeeded());
    unawaited(
      Future.wait([
        context.read<VideoProvider>().initialize(),
        context.read<SpeakerProvider>().initialize(),
        context.read<SubjectProvider>().initialize(),
        context.read<BookmarkProvider>().initialize(),
        context.read<NotificationProvider>().initialize(),
        context.read<BannerProvider>().initialize(),
        // Quiz answers still on the phone (sent offline, or a quiz that
        // closed while the app was shut) go out as soon as the app opens.
        context.read<QuizProvider>().flushPendingSubmissions(),
      ]),
    );
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
    _lifecycle.dispose();
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
    // Back from any other tab returns to Today first; back on Today exits.
    return PopScope(
      canPop: nav.isOnHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) nav.goHome();
      },
      child: HomeThemeScope(
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
