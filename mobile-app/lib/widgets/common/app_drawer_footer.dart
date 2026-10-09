import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../themes/app_colors.dart';
import '../../themes/app_fonts.dart';
import '../../themes/home_palette.dart';
import 'app_version_provider.dart';

/// Bottom of [AppDrawer]: "Developed by" with the D4DX logo, then the app
/// version.
class AppDrawerFooter extends StatelessWidget {
  const AppDrawerFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return ChangeNotifierProvider(
      create: (_) => AppVersionProvider(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Developed by',
                style: AppFonts.medium(color: p.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 4),
              // The blue mark is lost on the dark theme, so it goes white there.
              Image.asset(
                'assets/icons/D4DX _logo.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                color: p.isDark ? AppColors.white : null,
                colorBlendMode: BlendMode.srcIn,
                cacheHeight: (100 * MediaQuery.devicePixelRatioOf(context))
                    .round(),
              ),
              const SizedBox(height: 4),
              Consumer<AppVersionProvider>(
                builder: (_, v, _) => v.version.isEmpty
                    ? const SizedBox.shrink()
                    : Text(
                        'Version ${v.version}',
                        style: AppFonts.regular(
                          color: p.textMuted,
                          fontSize: 12,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
