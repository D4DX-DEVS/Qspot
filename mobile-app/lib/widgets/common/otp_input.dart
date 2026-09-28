import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../themes/app_theme.dart';
import '../../themes/app_fonts.dart';

/// Six (or N) separate digit boxes for OTP entry.
///
/// Typing auto-advances, backspace on an empty box steps back, and pasting a
/// whole code fills every box. The joined value is mirrored into [controller]
/// so callers can keep validating `controller.text` exactly as before.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.autofocus = true,
    this.enabled = true,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    final initial = widget.controller.text.replaceAll(RegExp(r'\D'), '');
    _controllers = List.generate(
      widget.length,
      (i) => TextEditingController(text: i < initial.length ? initial[i] : ''),
    );
    _focusNodes = List.generate(
      widget.length,
      (i) => FocusNode(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            _handleBackspace(i);
          }
          return KeyEventResult.ignored;
        },
      ),
    );

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes.first.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _value => _controllers.map((c) => c.text).join();

  void _publish() {
    final value = _value;
    widget.controller.text = value;
    if (value.length == widget.length) {
      widget.onCompleted?.call(value);
    }
  }

  void _handleChange(int index, String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');

    if (digits.length >= widget.length) {
      // A whole code (almost always a paste) replaces every box, no matter
      // which one had focus.
      for (var i = 0; i < widget.length; i++) {
        _controllers[i].text = digits[i];
      }
      _focusNodes[widget.length - 1].requestFocus();
      _publish();
      return;
    }

    if (digits.length > 1) {
      // Paste, or fast typing that outran the focus change: spread the digits
      // across the boxes starting at this one.
      for (var i = 0; i < digits.length && index + i < widget.length; i++) {
        _controllers[index + i].text = digits[i];
      }
      final nextIndex = (index + digits.length).clamp(0, widget.length - 1);
      _focusNodes[nextIndex].requestFocus();
    } else {
      _controllers[index].text = digits;
      if (digits.isNotEmpty && index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    }

    _publish();
  }

  void _handleBackspace(int index) {
    // Only step back when the current box is already empty, so one backspace
    // clears the box the user is looking at first.
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].text = '';
      _focusNodes[index - 1].requestFocus();
      _publish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < widget.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _box(i)),
        ],
      ],
    );
  }

  Widget _box(int index) {
    final isFilled = _controllers[index].text.isNotEmpty;

    return SizedBox(
      height: 58,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        enabled: widget.enabled,
        autofocus: false,
        keyboardType: TextInputType.number,
        textInputAction: index == widget.length - 1
            ? TextInputAction.done
            : TextInputAction.next,
        textAlign: TextAlign.center,
        // Deliberately larger than 1 so a pasted code can be distributed.
        maxLength: widget.length,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) => _handleChange(index, value),
        style: AppFonts.semiBold(fontSize: 22, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: isFilled ? AppTheme.primarySoft : AppTheme.surface,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(
              color: isFilled ? AppTheme.primary : AppTheme.border,
              width: isFilled ? 1.5 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
        ),
      ),
    );
  }
}
