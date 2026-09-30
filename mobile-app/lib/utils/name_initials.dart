/// Up to two upper-case initials from [name] ("Test Student" -> "TS"), or
/// "?" when the name is blank.
String nameInitials(String name) {
  final initials = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => String.fromCharCode(part.runes.first).toUpperCase())
      .join();
  return initials.isEmpty ? '?' : initials;
}
