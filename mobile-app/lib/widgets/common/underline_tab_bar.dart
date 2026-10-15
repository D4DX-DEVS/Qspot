import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../themes/app_fonts.dart';
import '../../themes/home_palette.dart';

/// Tabs in a row with a line under the chosen one, the same look as the tabs
/// in the lesson sheet. Scrolls sideways when the labels do not fit. A tab
/// can show a small lock after its label.
class UnderlineTabBar<T> extends StatelessWidget {
  const UnderlineTabBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelFor,
    this.isLocked,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T option) labelFor;

  /// Tabs this returns true for show a lock.
  final bool Function(T option)? isLocked;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        // Tabs that are narrower than the space still fill it, so the line
        // under them runs the full width.
        final minWidth = box.hasBoundedWidth ? box.maxWidth : 0.0;
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Divider(
                height: 1,
                thickness: 1,
                color: palette.cardBorder,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: minWidth),
                child: Row(
                  children: [
                    for (final option in options) _tab(palette, option),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tab(HomePalette palette, T option) {
    final active = option == selected;
    final locked = isLocked?.call(option) ?? false;
    final color = active ? palette.brand : palette.textMuted;
    final label = labelFor(option);
    return Semantics(
      button: true,
      selected: active,
      excludeSemantics: true,
      onTap: () => onSelected(option),
      label: locked ? '$label, locked' : label,
      child: InkWell(
        onTap: () => onSelected(option),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? palette.brand : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: active
                    ? AppFonts.bold(color: color, fontSize: 13)
                    : AppFonts.semiBold(color: color, fontSize: 13),
              ),
              if (locked) ...[
                const SizedBox(width: 5),
                Icon(LucideIcons.lock, size: 13, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
