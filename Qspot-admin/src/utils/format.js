// Formats a duration given in seconds as "H:MM:SS" or "M:SS". Single
// implementation shared across Videos, Video detail/stats and anywhere else
// a duration needs to be displayed.
export function formatDuration(totalSeconds) {
  const seconds = Math.max(0, Math.round(Number(totalSeconds) || 0));
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) {
    return `${h}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  }
  return `${m}:${String(s).padStart(2, '0')}`;
}

// Converts a `datetime-local` input value (no timezone) into an ISO 8601
// string with the browser's own offset, per CONTRACT.md: "Clients send ISO
// strings (new Date(local).toISOString())".
export function localDateTimeToISO(localValue) {
  if (!localValue) return '';
  const date = new Date(localValue);
  if (Number.isNaN(date.getTime())) return '';
  return date.toISOString();
}

// Converts an ISO string (or Date) back into a `datetime-local` input value
// in the browser's local time, for editing an existing ISO value.
export function isoToLocalDateTimeInput(isoValue) {
  if (!isoValue) return '';
  const date = new Date(isoValue);
  if (Number.isNaN(date.getTime())) return '';
  const pad = (n) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(
    date.getHours()
  )}:${pad(date.getMinutes())}`;
}

export function formatDateTime(isoString) {
  if (!isoString) return 'NA';
  const d = new Date(isoString);
  if (Number.isNaN(d.getTime())) return 'NA';
  return `${d.toLocaleDateString()} ${d.toLocaleTimeString()}`;
}
