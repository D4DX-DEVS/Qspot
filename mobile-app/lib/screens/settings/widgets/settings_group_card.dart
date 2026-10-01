import 'package:flutter/material.dart';

import '../../../widgets/common/surface_card.dart';

/// One white card holding several rows, with a hairline divider between
/// them that starts after the icon column.
class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      thickness: 1,
      indent: 72,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) divider,
            children[i],
          ],
        ],
      ),
    );
  }
}
