import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../../../widgets/common/gradient_card.dart';
import '../../../widgets/common/hero_tag_pill.dart';
import '../../../widgets/common/initials_avatar.dart';

/// Burgundy identity card for the Me tab: avatar, name, phone, tag pills
/// and an edit button.
class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({
    super.key,
    required this.name,
    required this.onEdit,
    this.phone = '',
    this.tags = const [],
  });

  final String name;
  final String phone;

  /// Short facts shown as pills, e.g. class and language.
  final List<String> tags;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 32),
            child: Row(
              children: [
                InitialsAvatar(
                  name: name,
                  size: 68,
                  gradient: HomePalette.of(context).heroGradient,
                  ringWidth: 2.5,
                ),
                const SizedBox(width: 16),
                Expanded(child: _details()),
              ],
            ),
          ),
          Positioned(
            top: -10,
            right: -12,
            child: PressableScale(
              child: IconButton(
                onPressed: onEdit,
                tooltip: 'Edit Profile',
                icon: const Icon(
                  LucideIcons.pencil,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: AppFonts.bold(color: AppColors.white, fontSize: 19)),
        if (phone.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            phone,
            style: AppFonts.regular(
              color: AppColors.white.withValues(alpha: 0.86),
              fontSize: 13.5,
            ),
          ),
        ],
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final tag in tags) HeroTagPill(label: tag)],
          ),
        ],
      ],
    );
  }
}
