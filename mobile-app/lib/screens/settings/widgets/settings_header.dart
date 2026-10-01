import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../auth/widgets/art/auth_art.dart';
import '../../auth/widgets/art/hanging_lantern_painter.dart';
import '../../auth/widgets/auth_back_button.dart';
import '../../home/widgets/today_sky_backdrop.dart';

/// Top of the settings page: soft sky and skyline with a hanging lantern, a
/// round back button, then a large title and a one-line subtitle.
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final topInset = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        // Fades out toward the bottom so the artwork melts into the page and
        // stays clear of the subtitle.
        Positioned.fill(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.transparent],
              stops: [0.35, 1],
            ).createShader(rect),
            child: const TodaySkyBackdrop(skylineOpacity: 0.6),
          ),
        ),
        const Positioned(
          top: 0,
          right: 20,
          width: 30,
          height: 110,
          child: AuthArt(painter: HangingLanternPainter.new),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, topInset + 10, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthBackButton(onPressed: onBack),
              const SizedBox(height: 14),
              Text(
                title,
                style: AppFonts.extraBold(
                  color: scheme.onSurface,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppFonts.regular(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
