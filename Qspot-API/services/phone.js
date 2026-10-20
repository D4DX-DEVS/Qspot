const countries = require('./phoneCountries.json');

const INDIA = '91';

// Mobile number lengths by country calling code, from
// tools/phone-countries/generate.mjs. Countries that share a code (+1 US and
// Canada, +7 Russia and Kazakhstan) are merged. No calling code starts with
// another one, so the first code that matches is the only one.
const plans = new Map();
for (const country of countries) {
  const plan = plans.get(country.dial) || { lengths: new Set(), trunkZero: false };
  country.lengths.forEach((length) => plan.lengths.add(length));
  plan.trunkZero = plan.trunkZero || country.trunkZero;
  plans.set(country.dial, plan);
}

// "+447400123456" -> { dial: '44', number: '7400123456', plan }, or null for
// an unknown country code.
const splitInternational = (digits) => {
  for (let size = 1; size <= 3; size += 1) {
    const plan = plans.get(digits.slice(0, size));
    if (plan) return { dial: digits.slice(0, size), number: digits.slice(size), plan };
  }
  return null;
};

// Indian numbers are saved as their 10 digits, the way every account was
// saved before other countries were allowed; any other number as
// "+<country code><number>". Every place that saves or looks up a number
// cleans it the same way, so "+91 98765 43210", "098765 43210" and
// "9876543210" are one account, and so are "+44 07400 123456" and
// "+447400123456". A number without "+" is Indian.
const normalizePhone = (raw) => {
  let phone = String(raw || '').replace(/[^\d+]/g, '');
  if (phone.startsWith('+')) {
    const parts = splitInternational(phone.replace(/\+/g, ''));
    if (!parts) return phone;
    const number = parts.plan.trunkZero ? parts.number.replace(/^0+/, '') : parts.number;
    return parts.dial === INDIA ? number : `+${parts.dial}${number}`;
  }
  if (phone.startsWith('91') && phone.length > 10) phone = phone.slice(2);
  else if (phone.startsWith('0')) phone = phone.replace(/^0+/, '');
  return phone.slice(-10);
};

// "10", "9 or 10", "7 to 13".
const describeLengths = (lengths) => {
  const sorted = [...lengths].sort((a, b) => a - b);
  if (sorted.length === 1) return String(sorted[0]);
  if (sorted.length === 2) return `${sorted[0]} or ${sorted[1]}`;
  const last = sorted[sorted.length - 1];
  if (last - sorted[0] === sorted.length - 1) return `${sorted[0]} to ${last}`;
  return `${sorted.slice(0, -1).join(', ')} or ${last}`;
};

// Why a number cleaned by normalizePhone cannot be used, or null when it can.
const phoneError = (phone) => {
  if (/^\d*$/.test(phone)) {
    return phone.length === 10 ? null : 'Enter a valid 10-digit phone number';
  }
  const parts = /^\+\d+$/.test(phone) ? splitInternational(phone.slice(1)) : null;
  if (!parts) return 'Enter a valid phone number with its country code';
  if (parts.plan.lengths.has(parts.number.length)) return null;
  return `Enter a valid ${describeLengths(parts.plan.lengths)}-digit phone number`;
};

module.exports = { normalizePhone, phoneError };
