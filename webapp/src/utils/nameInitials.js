// Up to two initials for an avatar ("Test Student" -> "TS"), or '?'.
export const nameInitials = (name) =>
  String(name ?? '')
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0].toUpperCase())
    .join('') || '?'
