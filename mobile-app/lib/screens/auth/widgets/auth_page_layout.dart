import 'package:flutter/material.dart';

import '../../../themes/app_colors.dart';
import '../../../themes/auth_palette.dart';

/// Shared frame for the auth screens: page colour, fixed top artwork and a
/// scrolling, phone-width content column with artwork at its foot.
///
/// The bottom artwork sits at the screen bottom when the content is short
/// and below the content when it is long, so it never covers a field.
/// [bottomArtOverlap] lets the content run into the (empty) top of the art.
/// [centerContent] centres short content vertically in the space above the
/// art instead of pinning it to the top.
class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({
    super.key,
    required this.children,
    this.topArt,
    this.topArtHeight = 0,
    this.bottomArt,
    this.bottomArtHeight = 0,
    this.bottomArtOverlap = 0,
    this.centerContent = false,
  });

  final List<Widget> children;
  final Widget? topArt;
  final double topArtHeight;
  final Widget? bottomArt;
  final double bottomArtHeight;
  final double bottomArtOverlap;
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AuthPalette.of(context).background,
      child: Stack(
        children: [
          if (topArt != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topArtHeight,
              child: topArt!,
            ),
          Scaffold(
            backgroundColor: AppColors.transparent,
            body: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Stack(
                    alignment: centerContent
                        ? Alignment.center
                        : AlignmentDirectional.topStart,
                    children: [
                      if (bottomArt != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: bottomArtHeight,
                          child: bottomArt!,
                        ),
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            12,
                            24,
                            24 + bottomArtHeight - bottomArtOverlap,
                          ),
                          child: Center(
                            // Keeps the column phone-shaped on tablets and
                            // desktop.
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: children,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
