import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'floating_nav_bar_button.dart';
import 'floating_nav_bar_item.dart';

/// Floating, pill-shaped bottom navigation bar with a sliding highlight
/// behind the selected destination. Stateless: the parent owns [currentIndex].
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  }) : assert(items.length >= 2);

  /// Widest the bar grows (landscape / tablets); it stays centered beyond this.
  static const double maxWidth = 560;

  final List<FloatingNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Maps the selected index onto -1..1 so the highlight slides between slots.
    final slot = -1 + 2 * currentIndex / (items.length - 1);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedAlign(
                        alignment: AlignmentDirectional(slot, 0),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        child: FractionallySizedBox(
                          widthFactor: 1 / items.length,
                          heightFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: FloatingNavBarButton(
                              item: items[i],
                              selected: i == currentIndex,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onTap(i);
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
