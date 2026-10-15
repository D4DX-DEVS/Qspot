import 'package:flutter/material.dart';

/// Full QSPOT logo, colour in light mode and white in dark mode.
///
/// The asset is a landscape page with the logo in the middle, so it is
/// cropped to the visible logo (~78% wide, ~30% tall). [width] is the width
/// of the uncropped image; the logo shows at about 78% of it.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.width = 180});

  final double width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: Align(
        widthFactor: 0.78,
        heightFactor: 0.3,
        child: Image.asset(
          isDark
              ? 'assets/icons/Logo 01.png'
              : 'assets/icons/Logo 01 Color.png',
          width: width,
          fit: BoxFit.contain,
          // Decode near display size instead of the 4961 px source.
          cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).round(),
        ),
      ),
    );
  }
}
