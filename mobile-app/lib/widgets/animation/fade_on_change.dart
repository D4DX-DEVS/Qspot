import 'package:flutter/material.dart';

import 'motion.dart';

/// Replays a short fade-and-rise on [child] whenever [trigger] changes, without
/// rebuilding it. Handy for tabs that stay alive in an `IndexedStack`.
class FadeOnChange extends StatefulWidget {
  const FadeOnChange({super.key, required this.trigger, required this.child});

  final Object? trigger;
  final Widget child;

  @override
  State<FadeOnChange> createState() => _FadeOnChangeState();
}

class _FadeOnChangeState extends State<FadeOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Motion.medium,
      value: 1,
    );
    _progress = CurvedAnimation(parent: _controller, curve: Motion.smooth);
  }

  @override
  void didUpdateWidget(covariant FadeOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && !Motion.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: 0.4 + 0.6 * _progress.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _progress.value) * 10),
          child: child,
        ),
      ),
    );
  }
}
