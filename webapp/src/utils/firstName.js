// First word of [name] ("Test Student" -> "Test"), or '' when blank
// (mobile-app/lib/utils/first_name.dart).
export const firstName = (name) => String(name ?? '').trim().split(/\s+/)[0] ?? ''
