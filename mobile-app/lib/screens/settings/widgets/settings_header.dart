import 'package:flutter/material.dart';

import '../../../themes/app_fonts.dart';
import '../../../widgets/animation/motion.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../auth/widgets/art/auth_art.dart';
import '../../auth/widgets/art/hanging_lantern_painter.dart';
import '../../auth/widgets/auth_back_button.dart';
import '../../home/widgets/today_sky_backdrop.dart';

/// Top of the settings page: soft sky and skyline with a hanging lantern, a
/// round back button, then a compact page title and a one-line subtitle.
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
        Positioned(
          top: 0,
          right: 20,
          width: 30,
          height: 110,
          // Swings once from the hook and settles.
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.15, end: 0),
            duration: Motion.reduced(context) ? Duration.zero : Motion.slow,
            curve: Curves.elasticOut,
            builder: (_, angle, child) => Transform.rotate(
              angle: angle,
              alignment: Alignment.topCenter,
              child: child,
            ),
            child: const AuthArt(painter: HangingLanternPainter.new),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, topInset + 10, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthBackButton(onPressed: onBack),
              const SizedBox(height: 14),
              StaggeredEntrance(
                child: Text(
                  title,
                  style: Theme.of(context).appBarTheme.titleTextStyle,
                ),
              ),
              const SizedBox(height: 4),
              StaggeredEntrance(
                index: 1,
                child: Text(
                  subtitle,
                  style: AppFonts.regular(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
