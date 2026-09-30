import 'package:flutter/widgets.dart';

/// A strong accent colour with the soft tint drawn behind it, e.g. an amber
/// icon on a pale amber tile.
@immutable
class AccentTone {
  const AccentTone(this.color, this.soft);

  /// Icons, links and short labels.
  final Color color;

  /// Tile, chip and pill backgrounds behind [color].
  final Color soft;

  @override
  bool operator ==(Object other) =>
      other is AccentTone && other.color == color && other.soft == soft;

  @override
  int get hashCode => Object.hash(color, soft);
}
