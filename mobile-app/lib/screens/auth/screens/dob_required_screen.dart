import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';
import '../provider/dob_required_provider.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../widgets/art/auth_art.dart';
import '../widgets/art/bottom_waves_painter.dart';
import '../widgets/art/corner_wave_painter.dart';
import '../widgets/auth_brand_mark.dart';
import '../widgets/auth_headline.dart';
import '../widgets/auth_page_layout.dart';
import '../widgets/auth_theme_scope.dart';
import '../widgets/dob_required_form.dart';

/// Shown once to a signed-in student whose account has no date of birth.
/// Sign-in now needs one, so the app asks for it before going any further.
class DobRequiredScreen extends StatelessWidget {
  const DobRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DobRequiredProvider(
        applyUser: context.read<AuthProvider>().updateUser,
      ),
      child: AuthThemeScope(
        child: AuthPageLayout(
          topArt: const AuthArt(painter: CornerWavePainter.new),
          topArtHeight: 230,
          bottomArt: const AuthArt(painter: BottomWavesPainter.new),
          bottomArtHeight: 120,
          children: const [
            StaggeredEntrance(index: 0, child: AuthBrandMark(size: 116)),
            StaggeredEntrance(
              index: 1,
              child: AuthHeadline(
                title: 'Add Your ',
                accent: 'Date of Birth',
                subtitle:
                    'You now sign in with your phone number and date of birth. Add yours to keep using your account.',
                fontSize: 28,
              ),
            ),
            SizedBox(height: 24),
            StaggeredEntrance(index: 2, child: DobRequiredForm()),
          ],
        ),
      ),
    );
  }
}
