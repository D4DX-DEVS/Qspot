import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/badged_icon_button.dart';
import '../../../widgets/common/initials_avatar.dart';

/// Greeting, learner name and a gentle tagline, with the notifications bell
/// and profile avatar on the right.
class TodayHeader extends StatelessWidget {
  const TodayHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.onNotifications,
    required this.onProfile,
    this.tagline = 'Keep learning, one step at a time',
    this.unreadCount = 0,
  });

  final String greeting;
  final String name;
  final String tagline;
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AppFonts.medium(color: palette.text, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.bold(
                  color: palette.text,
                  fontSize: 24,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.regular(
                        color: palette.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(Icons.eco_rounded, color: palette.amber.color, size: 15),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        BadgedIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          count: unreadCount,
          onPressed: onNotifications,
        ),
        const SizedBox(width: 4),
        Semantics(
          label: 'Open profile',
          button: true,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onProfile,
            child: InitialsAvatar(
              name: name,
              size: 48,
              gradient: palette.heroGradient,
            ),
          ),
        ),
      ],
    );
  }
}
