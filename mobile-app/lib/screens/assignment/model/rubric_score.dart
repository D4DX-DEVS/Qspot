/// A teacher's score for one part of work marked by parts, e.g.
/// "Makharij 3 / 4".
class RubricScore {
  const RubricScore({
    required this.label,
    required this.points,
    required this.maxPoints,
  });

  final String label;
  final num points;
  final num maxPoints;

  static List<RubricScore> listFrom(Object? json) {
    if (json is! List) return const [];
    return [
      for (final item in json)
        if (item is Map && (item['label'] ?? '').toString().isNotEmpty)
          RubricScore(
            label: item['label'].toString(),
            points: num.tryParse('${item['points'] ?? ''}') ?? 0,
            maxPoints: num.tryParse('${item['maxPoints'] ?? ''}') ?? 0,
          ),
    ];
  }

  static String _number(num value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';

  /// "3 / 4".
  String get scoreLabel => '${_number(points)} / ${_number(maxPoints)}';
}
