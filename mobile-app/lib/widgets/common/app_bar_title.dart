import 'package:flutter/material.dart';

import 'fit_text.dart';

/// Plain-text title for [CommonAppBar] that is always fully visible.
///
/// The text wraps onto as many lines as the bar's height allows; when it is
/// too long even for that, the font is made smaller until everything fits
/// (instead of being cut with "...").
class AppBarTitle extends StatelessWidget {
  const AppBarTitle(
    this.text, {
    super.key,
    this.centered = false,
    this.height = kToolbarHeight,
  });

  final String text;

  /// Centres wrapped lines, matching an app bar with a centred title.
  final bool centered;

  /// Room the title may use; matches the app bar's toolbar by default.
  final double height;

  static const double _verticalGap = 4;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Align(
        alignment: centered
            ? Alignment.center
            : AlignmentDirectional.centerStart,
        child: FitText(
          text,
          maxHeight: height - _verticalGap,
          minFontSize: 11,
          textAlign: centered ? TextAlign.center : TextAlign.start,
        ),
      ),
    );
  }
}
