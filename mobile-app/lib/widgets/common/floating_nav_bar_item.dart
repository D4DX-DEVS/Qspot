import 'package:flutter/widgets.dart';

/// A single destination shown in a `FloatingNavBar`.
class FloatingNavBarItem {
  const FloatingNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
