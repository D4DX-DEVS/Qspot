import 'package:flutter/material.dart';

import 'motion.dart';

/// A deliberately quiet idle cue for the one action a learner should take
/// next. It stops completely when the user has reduced motion enabled.
class IdleAttention extends StatefulWidget {
  const IdleAttention({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<IdleAttention> createState() => _IdleAttentionState();
}

class _IdleAttentionState extends State<IdleAttention>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant IdleAttention oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _syncAnimation();
  }

  void _syncAnimation() {
    if (!widget.enabled || Motion.reduced(context)) {
      _controller
        ..stop()
        ..value = 0;
      return;
    }
    if (!_controller.isAnimating) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || Motion.reduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (_, child) => Transform.scale(
        // Keep the movement below the threshold where it feels like a
        // notification; this is only a soft affordance cue.
        scale: 1 + (_controller.value * 0.014),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
