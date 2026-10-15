import 'package:flutter/material.dart';

import '../../screens/common/widgets/home_theme_scope.dart';
import '../../themes/home_palette.dart';

/// Burgundy home theme plus a rounded page-coloured surface for a modal
/// bottom sheet. Show the sheet with a transparent `backgroundColor` and
/// put this at the top of its builder.
///
/// The phone's left and right safe-area insets (the notch side in landscape)
/// are dropped for the content: a modal sheet is capped at 640 wide and
/// centred, so it never reaches those edges, and a `SafeArea` inside it would
/// otherwise push the content inward. The bottom inset is kept.
class HomeSheetShell extends StatelessWidget {
  const HomeSheetShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HomeThemeScope(
      child: Builder(
        builder: (context) => Material(
          color: HomePalette.of(context).background,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeRight: true,
            child: child,
          ),
        ),
      ),
    );
  }
}
