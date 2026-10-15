import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/info_note_card.dart';
import '../../../widgets/common/soft_outline_button.dart';
import 'offline_illustration.dart';

/// Scrollable "progress is unavailable" state with a retry button, so it
/// also works inside a pull-to-refresh.
class ProgressUnavailableView extends StatelessWidget {
  const ProgressUnavailableView({
    super.key,
    required this.onRetry,
    this.message,
  });

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        48,
        20,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        const StaggeredEntrance(child: Center(child: OfflineIllustration())),
        const SizedBox(height: 24),
        StaggeredEntrance(
          index: 1,
          child: Text(
            'Progress Is Unavailable',
            textAlign: TextAlign.center,
            style: AppFonts.bold(color: palette.text, fontSize: 20),
          ),
        ),
        const SizedBox(height: 8),
        StaggeredEntrance(
          index: 2,
          child: Text(
            message ?? 'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: AppFonts.regular(color: palette.textMuted, fontSize: 14),
          ),
        ),
        const SizedBox(height: 24),
        StaggeredEntrance(
          index: 3,
          child: Center(
            child: SoftOutlineButton(
              label: 'Try Again',
              icon: LucideIcons.refreshCw,
              onPressed: onRetry,
            ),
          ),
        ),
        const SizedBox(height: 32),
        StaggeredEntrance(
          index: 4,
          child: InfoNoteCard(
            icon: LucideIcons.wifi,
            tone: palette.slate,
            message:
                'Make sure you are connected to the internet to view your learning progress.',
          ),
        ),
      ],
    );
  }
}
