import 'package:flutter/material.dart';

/// App-wide top bar. Colours, elevation and title style come from the active
/// theme's `appBarTheme`, so screens only pass content.
///
/// Use [title] for plain text; pass [titleWidget] instead when the bar needs
/// custom content (e.g. a search field). [titleWidget] wins when both are set.
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.centerTitle,
    this.bottom,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final bool? centerTitle;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title:
          titleWidget ??
          (title == null
              ? null
              : Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis)),
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      bottom: bottom,
    );
  }
}
