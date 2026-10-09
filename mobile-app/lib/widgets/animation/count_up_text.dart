import 'package:flutter/material.dart';

import 'motion.dart';

/// Text whose first whole number counts up from zero when it first shows
/// ("12 days" runs 0 days, 1 days ... 12 days). Text with no plain number in
/// it, or with a decimal or thousands separator, is shown as is.
class CountUpText extends StatelessWidget {
  const CountUpText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  // prefix, a whole number (not part of 4.5, 1,200 or 10:30), then the rest.
  static final RegExp _pattern = RegExp(r'^(\D*?)(\d{1,7})(?!\d|[.,:]\d)(.*)$');

  @override
  Widget build(BuildContext context) {
    final match = _pattern.firstMatch(text);
    if (match == null || Motion.reduced(context)) return _text(text);
    final prefix = match.group(1)!;
    final target = int.parse(match.group(2)!);
    final suffix = match.group(3)!;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: target.toDouble()),
      duration: Motion.slow,
      curve: Motion.smooth,
      builder: (_, v, __) => _text('$prefix${v.round()}$suffix'),
    );
  }

  Text _text(String value) => Text(
    value,
    style: style,
    maxLines: maxLines,
    overflow: overflow,
    textAlign: textAlign,
  );
}
