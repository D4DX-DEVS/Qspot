import 'package:flutter/material.dart';

import '../../themes/app_fonts.dart';
import '../../themes/home_palette.dart';
import 'soft_icon_tile.dart';

/// Centered empty / error / no-results message: a big tinted icon circle, a
/// bold title, a short line, and an optional retry button.
class StateMessageView extends StatelessWidget {
  const StateMessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// Shows a "Retry" button when set.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SoftIconTile(icon: icon, tone: p.rose, size: 84, circle: true),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppFonts.bold(color: p.text, fontSize: 19),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: AppFonts.regular(
                  color: p.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.brand,
                  foregroundColor: p.card,
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
