import 'package:flutter/material.dart';

import '../animation/pop_on_change.dart';
import '../animation/pressable_scale.dart';
import 'floating_nav_bar_item.dart';

/// One tappable slot inside a `FloatingNavBar`. Purely presentational; the
/// sliding highlight behind it is drawn by the bar.
class FloatingNavBarButton extends StatelessWidget {
  const FloatingNavBarButton({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final FloatingNavBarItem item;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      label: item.label,
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: PressableScale(
        pressedScale: 0.9,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: selected ? 1.08 : 1.0,
                  duration: _duration,
                  curve: Curves.easeOutBack,
                  child: PopOnChange(
                    active: selected,
                    child: AnimatedSwitcher(
                      duration: _duration,
                      child: Icon(
                        selected ? item.activeIcon : item.icon,
                        key: ValueKey(selected),
                        size: 22,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: _duration,
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: color,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                  // Shrinks a long label (or big text) to fit its slot.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(item.label, maxLines: 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
