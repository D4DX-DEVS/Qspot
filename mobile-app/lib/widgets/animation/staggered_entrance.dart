import 'package:flutter/material.dart';

import 'motion.dart';

/// Fades and slides [child] up the first time it appears. Give list items
/// their [index] and they arrive one after another; items past [maxStaggered]
/// (usually scrolled in later) start straight away.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.step = const Duration(milliseconds: 60),
    this.maxStaggered = 8,
    this.rise = 20,
  });

  final Widget child;
  final int index;

  /// Gap between one item starting and the next.
  final Duration step;
  final int maxStaggered;

  /// How far (in logical pixels) the child travels upward while fading in.
  final double rise;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final delay = widget.index < widget.maxStaggered
        ? widget.step * widget.index
        : Duration.zero;
    final total = delay + Motion.entrance;
    _controller = AnimationController(vsync: this, duration: total);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: Motion.smooth,
      ),
    );
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) _controller.value = 1;
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
        opacity: _progress.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _progress.value) * widget.rise),
          child: child,
        ),
      ),
    );
  }
}
