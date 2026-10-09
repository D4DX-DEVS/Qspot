import 'package:flutter/material.dart';

import '../../themes/accent_tone.dart';
import '../../themes/app_fonts.dart';
import '../../themes/home_palette.dart';
import 'home_sheet_shell.dart';
import 'soft_icon_tile.dart';

/// Short bottom sheet that explains why something can't be opened: a tinted
/// icon circle, a bold title, a friendly line and one dismiss button.
/// Sizes to its content and scrolls when the screen is short (landscape).
class NoticeSheet extends StatelessWidget {
  const NoticeSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone,
    this.buttonLabel = 'Got It',
  });

  final IconData icon;
  final String title;
  final String message;

  /// Picks the icon tone from the sheet's own palette, so it follows the
  /// phone's light/dark setting. Defaults to slate.
  final AccentTone Function(HomePalette p)? tone;
  final String buttonLabel;

  static Future<void> show(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    AccentTone Function(HomePalette p)? tone,
    String buttonLabel = 'Got It',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HomeSheetShell(
        child: NoticeSheet(
          icon: icon,
          title: title,
          message: message,
          tone: tone,
          buttonLabel: buttonLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SoftIconTile(
              icon: icon,
              tone: tone?.call(p) ?? p.slate,
              size: 72,
              circle: true,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppFonts.bold(color: p.text, fontSize: 19),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.regular(
                color: p.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.brand,
                  foregroundColor: p.card,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: AppFonts.semiBold(fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
