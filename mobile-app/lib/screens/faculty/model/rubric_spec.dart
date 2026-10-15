/// One part of an assignment marked by parts, e.g. "Makharij" out of 4.
class RubricPart {
  const RubricPart({required this.label, required this.maxPoints});

  final String label;
  final int maxPoints;
}

/// Whether an assignment is marked by parts, and its parts.
class RubricSpec {
  const RubricSpec({required this.enabled, required this.parts});

  final bool enabled;
  final List<RubricPart> parts;

  bool get isOn => enabled && parts.isNotEmpty;
  int get total => parts.fold(0, (sum, p) => sum + p.maxPoints);

  factory RubricSpec.fromJson(Object? json) {
    if (json is! Map) return const RubricSpec(enabled: false, parts: []);
    final criteria = json['criteria'] is List ? json['criteria'] as List : [];
    return RubricSpec(
      enabled: json['enabled'] == true,
      parts: [
        for (final item in criteria)
          if (item is Map && (item['label'] ?? '').toString().isNotEmpty)
            RubricPart(
              label: item['label'].toString(),
              maxPoints: int.tryParse('${item['maxPoints'] ?? ''}') ?? 0,
            ),
      ].where((p) => p.maxPoints > 0).toList(),
    );
  }
}
