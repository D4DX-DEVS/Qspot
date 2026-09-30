import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/auth_palette.dart';
import '../../auth/provider/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../faculty/screens/faculty_home_screen.dart';
import 'main_navigation_screen.dart';
import '../widgets/splash_artwork.dart';

/// Brand splash in the sign-in screens' style, following the phone's
/// light/dark setting: cream with the colour logo in light mode, logo
/// burgundy with the white logo in dark mode, over faded login-style artwork.
///
/// Nothing else competes with the mark — the same idea as the reference apps
/// that open on a single flat colour with their logo in the middle.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Light icons on the dark-mode burgundy, dark icons on the light cream.
    final isDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        // iOS reads the bar brightness instead: dark bar = light icons.
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark
            ? AppColors.authBrand
            : AppColors.authLightBackground,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutBack),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSplashSequence();
    });
  }

  Future<void> _startSplashSequence() async {
    _animationController.forward();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();

    await Future.delayed(const Duration(milliseconds: 30000));

    if (!mounted) return;

    // Leaving the splash's dark brand background for the app's normal
    // (white) background, so the system nav bar needs to switch back to
    // dark icons on a light bar instead of the splash's light-on-dark style.
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            authProvider.isAuthenticated
            ? (authProvider.user?.role == 'faculty'
                  ? const FacultyHomeScreen()
                  : const MainNavigationScreen())
            : const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    // Safety net in case the widget is disposed without _startSplashSequence
    // ever completing (e.g. hot restart) — don't leave the system nav bar
    // stuck on the splash's maroon color.
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final palette = isDark ? AuthPalette.splash : AuthPalette.light;
    const logoWidth = 210.0;
    return Scaffold(
      backgroundColor: palette.background,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SplashArtwork(palette: palette),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                // Full logo (mark, wordmark, tagline). The colour version's
                // dark tagline needs the light background.
                child: Image.asset(
                  isDark
                      ? 'assets/icons/sp-logo-white.png'
                      : 'assets/icons/sp-logo.png',
                  width: logoWidth,
                  fit: BoxFit.contain,
                  // Decode near display size instead of the 2075 px source.
                  cacheWidth:
                      (logoWidth * MediaQuery.devicePixelRatioOf(context))
                          .round(),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: child,
                      );
                    },
                    child: Text(
                      'Developed by D4DX Innovations LLP',
                      style: AppFonts.medium(
                        color: isDark ? AppColors.white70 : palette.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
