/// First word of [name] ("Test Student" -> "Test"), or an empty string when
/// the name is blank.
String firstName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  return parts.first;
}
