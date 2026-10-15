import 'dart:math' as math;
import 'dart:ui' show Color;

/// One piece of confetti: where it starts, how it flies, and how it looks.
class ConfettiParticle {
  const ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
    required this.round,
  });

  /// Launch direction in radians (0 = right, -pi/2 = straight up).
  final double angle;

  /// Launch speed as a fraction of the area height per animation run.
  final double speed;
  final double spin;
  final double size;
  final Color color;
  final bool round;

  /// Builds [count] pieces fanning upward, coloured from [palette].
  static List<ConfettiParticle> generate({
    required int count,
    required List<Color> palette,
    int seed = 7,
  }) {
    final random = math.Random(seed);
    return List<ConfettiParticle>.generate(count, (_) {
      return ConfettiParticle(
        angle: -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi * 0.9,
        speed: 0.55 + random.nextDouble() * 0.75,
        spin: (random.nextDouble() - 0.5) * 14,
        size: 5 + random.nextDouble() * 6,
        color: palette[random.nextInt(palette.length)],
        round: random.nextBool(),
      );
    });
  }
}
