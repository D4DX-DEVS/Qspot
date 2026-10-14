import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/tinted_pill_link.dart';

/// Tells the student that finished answers are still on the phone and not yet
/// accepted by the server, with a button to send them now.
class QuizPendingBanner extends StatelessWidget {
  const QuizPendingBanner({
    super.key,
    required this.message,
    required this.onSend,
    this.sending = false,
  });

  final String message;
  final VoidCallback onSend;

  /// While true the button is idle and reads "Sending…".
  final bool sending;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.amber.soft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.cloudUpload, color: p.amber.color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: AppFonts.regular(
                      color: p.text,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TintedPillLink(
                label: sending ? 'Sending…' : 'Send Now',
                tone: p.amber,
                onTap: sending ? null : onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
