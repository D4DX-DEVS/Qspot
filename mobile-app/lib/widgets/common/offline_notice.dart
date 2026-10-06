import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../themes/home_palette.dart';

/// A compact explanation shown when cached content is available but the
/// latest server data cannot be reached.
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: palette.amber.soft,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(LucideIcons.wifiOff, size: 18, color: palette.amber.color),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: palette.text, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
