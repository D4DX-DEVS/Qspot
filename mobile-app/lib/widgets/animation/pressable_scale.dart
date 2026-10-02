import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'motion.dart';

/// Squishes [child] a little while a finger is on it and springs it back on
/// release. Listens to raw pointer events, so taps still reach the button or
/// card inside untouched.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.96,
    this.enabled = true,
    this.haptic = false,
  });

  final Widget child;
  final double pressedScale;
  final bool enabled;

  /// Adds a light buzz on touch-down. Keep for real buttons, not scroll rows.
  final bool haptic;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  final ValueNotifier<bool> _pressed = ValueNotifier<bool>(false);
  Offset? _downAt;

  @override
  void dispose() {
    _pressed.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent event) {
    if (!widget.enabled) return;
    _downAt = event.position;
    _pressed.value = true;
    if (widget.haptic) HapticFeedback.selectionClick();
  }

  // A drag means the user is scrolling, not pressing.
  void _move(PointerMoveEvent event) {
    final start = _downAt;
    if (start != null && (event.position - start).distance > kTouchSlop) {
      _release();
    }
  }

  void _release([PointerEvent? _]) {
    _downAt = null;
    _pressed.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    return Listener(
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _release,
      onPointerCancel: _release,
      child: ValueListenableBuilder<bool>(
        valueListenable: _pressed,
        child: widget.child,
        builder: (_, pressed, child) {
          final active = pressed && !reduced;
          return AnimatedScale(
            scale: active ? widget.pressedScale : 1,
            duration: active ? Motion.fast : Motion.medium,
            curve: active ? Curves.easeOut : Motion.bounce,
            child: child,
          );
        },
      ),
    );
  }
}
