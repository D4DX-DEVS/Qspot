import 'package:flutter/material.dart';

/// Text that is always fully visible inside a box of limited height.
///
/// It wraps as usual; if the result is too tall (or a single word is wider
/// than the box) the font is made smaller step by step until everything fits.
/// If even [minFontSize] is not enough, the whole text is scaled down.
class FitText extends StatelessWidget {
  const FitText(
    this.text, {
    super.key,
    required this.maxHeight,
    this.style,
    this.textAlign,
    this.minFontSize = 10,
  });

  final String text;

  /// Tallest the wrapped text may be.
  final double maxHeight;

  /// Merged over the ambient [DefaultTextStyle].
  final TextStyle? style;
  final TextAlign? textAlign;
  final double minFontSize;

  static const double _step = 0.5;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final oneWordPerLine = text.trim().split(RegExp(r'\s+')).join('\n');

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        TextPainter painterFor(String value, double size) => TextPainter(
          text: TextSpan(
            text: value,
            style: base.copyWith(fontSize: size),
          ),
          textDirection: direction,
          textScaler: scaler,
          textAlign: textAlign ?? TextAlign.start,
        );

        bool fits(double size) {
          final wrapped = painterFor(text, size)..layout(maxWidth: maxWidth);
          final tallEnough = wrapped.height <= maxHeight;
          wrapped.dispose();
          if (!tallEnough) return false;
          // One word per line, so the widest line is the widest word: it must
          // fit on a line of its own instead of being split.
          final words = painterFor(oneWordPerLine, size)..layout();
          final widest = words.width;
          words.dispose();
          return widest <= maxWidth;
        }

        var size = base.fontSize ?? 14;
        while (size > minFontSize && !fits(size)) {
          size -= _step;
        }

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Text(
                text,
                softWrap: true,
                maxLines: null,
                overflow: TextOverflow.visible,
                textAlign: textAlign,
                style: base.copyWith(fontSize: size),
              ),
            ),
          ),
        );
      },
    );
  }
}
