import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/info_note_card.dart';
import '../../../widgets/common/soft_outline_button.dart';
import 'offline_illustration.dart';

/// Scrollable "progress is unavailable" state with a retry button, so it
/// also works inside a pull-to-refresh.
class ProgressUnavailableView extends StatelessWidget {
  const ProgressUnavailableView({super.key, required this.onRetry});

  final VoidCallback onRetry;

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
        const Center(child: OfflineIllustration()),
        const SizedBox(height: 24),
        Text(
          'Progress is unavailable',
          textAlign: TextAlign.center,
          style: AppFonts.bold(color: palette.text, fontSize: 20),
        ),
        const SizedBox(height: 8),
        Text(
          'Check your connection and try again.',
          textAlign: TextAlign.center,
          style: AppFonts.regular(color: palette.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Center(
          child: SoftOutlineButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ),
        const SizedBox(height: 32),
        InfoNoteCard(
          icon: Icons.wifi_rounded,
          tone: palette.slate,
          message:
              'Make sure you are connected to the internet to view your learning progress.',
        ),
      ],
    );
  }
}
