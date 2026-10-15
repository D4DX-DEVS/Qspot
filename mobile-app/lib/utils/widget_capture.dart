import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Reads pixels and position from a widget wrapped in a [RepaintBoundary]
/// that carries a [GlobalKey].
class WidgetCapture {
  WidgetCapture._();

  /// PNG of the boundary under [key], drawn at its own layout size times
  /// [pixelRatio] (any scaling applied above it on screen is ignored).
  static Future<Uint8List> png(GlobalKey key, {double pixelRatio = 3}) async {
    final boundary = key.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('Nothing to capture: the widget is not on screen.');
    }
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not encode the capture.');
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// On-screen rectangle of the widget under [key], e.g. to anchor the iPad
  /// share popover to it.
  static Rect? globalRect(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
