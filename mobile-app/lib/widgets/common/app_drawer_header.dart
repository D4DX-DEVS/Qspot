import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../themes/app_fonts.dart';
import '../../themes/home_palette.dart';
import 'app_logo.dart';
import 'frosted_panel.dart';
import 'initials_avatar.dart';
import 'square_icon_action.dart';

/// Top of [AppDrawer]: logo with a collapse button, then a frosted profile
/// card with the learner's avatar overlapping its top edge, their name and a
/// one-line subtitle (class or phone).
class AppDrawerHeader extends StatelessWidget {
  const AppDrawerHeader({
    super.key,
    required this.name,
    required this.subtitle,
    required this.onClose,
  });

  final String name;
  final String subtitle;
  final VoidCallback onClose;

  static const double _avatarSize = 60;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              const AppLogo(width: 120),
              const Spacer(),
              SquareIconAction(
                icon: LucideIcons.chevronsLeft,
                tooltip: 'Close',
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: _avatarSize / 2),
                child: FrostedPanel(
                  borderRadius: BorderRadius.circular(24),
                  opacity: 0.5,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      _avatarSize / 2 + 10,
                      12,
                      16,
                    ),
                    child: Column(
                      children: [
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: AppFonts.bold(color: p.text, fontSize: 18),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: AppFonts.regular(
                              color: p.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              InitialsAvatar(
                name: name,
                size: _avatarSize,
                color: p.brand,
                ringWidth: 3,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
