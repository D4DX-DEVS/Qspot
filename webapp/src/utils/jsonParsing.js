// Defensive readers for values from the API and saved JSON
// (mobile-app/lib/utils/json_parsing.dart). Admin-edited fields can arrive as
// numbers or numeric strings.
export function jsonInt(value) {
  if (typeof value === 'number') return Number.isFinite(value) ? Math.trunc(value) : null
  const raw = value == null ? '' : String(value).trim()
  if (raw === '') return null
  const parsed = Number(raw)
  if (!Number.isFinite(parsed) || parsed !== Math.trunc(parsed)) return null
  return parsed
}

export function jsonDouble(value) {
  if (typeof value === 'number') return Number.isFinite(value) ? value : null
  const raw = value == null ? '' : String(value).trim()
  if (raw === '') return null
  const parsed = Number(raw)
  return Number.isFinite(parsed) ? parsed : null
}

// A date from the API (UTC ISO string), or null.
export function parseDate(value) {
  if (typeof value !== 'string' || value === '') return null
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? null : date
}

export const text = (value, fallback = '') => {
  const t = value == null ? '' : String(value).trim()
  return t === '' ? fallback : t
}
