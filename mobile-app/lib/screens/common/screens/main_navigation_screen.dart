import 'package:flutter/material.dart';

import '../../../themes/app_theme.dart';
import '../../home/screens/redesigned_home_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../progress/screens/progress_screen.dart';
import '../../subject/screens/subject_list_screen.dart';
import '../../practice/screens/practice_hub_screen.dart';

/// Primary learner shell for the daily learning loop.
class MainNavigationScreen extends StatefulWidget {
  final int? currentIndex;

  const MainNavigationScreen({super.key, this.currentIndex});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

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
    _currentIndex = widget.currentIndex ?? 0;
  }

  @override
  void didUpdateWidget(covariant MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != null && widget.currentIndex != _currentIndex) {
      setState(() => _currentIndex = widget.currentIndex!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _screens.length) _currentIndex = 0;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _bottomBar() {
    final items = [
      _NavItem(Icons.today_outlined, Icons.today, 'Today'),
      _NavItem(Icons.menu_book_outlined, Icons.menu_book, 'Learn'),
      _NavItem(Icons.edit_note_outlined, Icons.edit_note, 'Practice'),
      _NavItem(Icons.insights_outlined, Icons.insights, 'Progress'),
      _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Me'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(child: _navItem(items[index], index)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(_NavItem item, int index) {
    final active = _currentIndex == index;
    final color = active ? AppTheme.primary : AppTheme.textMuted;
    return Semantics(
      label: item.label,
      button: true,
      selected: active,
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: active ? AppTheme.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  active ? item.activeIcon : item.icon,
                  size: 21,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
