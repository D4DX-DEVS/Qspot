// Date of birth is a sign-in credential, so it is read and compared in exactly
// one way: a calendar date written YYYY-MM-DD, stored as UTC midnight.

const DOB_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;
const MAX_AGE_YEARS = 100;

// Returns a Date at UTC midnight, or null when the value is not a real
// calendar date, is in the future, or is more than 100 years ago.
const parseDob = (value, now = new Date()) => {
  const match = DOB_PATTERN.exec(String(value ?? '').trim());
  if (!match) return null;

  const [year, month, day] = [Number(match[1]), Number(match[2]), Number(match[3])];
  const date = new Date(Date.UTC(year, month - 1, day));
  // Date.UTC rolls 2010-02-31 over to March, so check it survived unchanged.
  if (
    date.getUTCFullYear() !== year ||
    date.getUTCMonth() !== month - 1 ||
    date.getUTCDate() !== day
  ) {
    return null;
  }

  const today = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  if (date.getTime() > today) return null;
  if (year < now.getUTCFullYear() - MAX_AGE_YEARS) return null;
  return date;
};

// The stored date as YYYY-MM-DD, or '' when there is none.
const dobKey = (date) => (date instanceof Date && !Number.isNaN(date.getTime())
  ? date.toISOString().slice(0, 10)
  : '');

const sameDob = (stored, parsed) => {
  const key = dobKey(stored);
  return key !== '' && key === dobKey(parsed);
};

module.exports = { parseDob, dobKey, sameDob };
