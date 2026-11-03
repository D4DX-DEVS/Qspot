// A student's name is their sign-in check, so it is compared in exactly one
// way: spaces and capitals are ignored, so "RaMu K" signs in "ramu k".
const nameKey = (value) => String(value ?? '').replace(/\s+/g, '').toLowerCase();

// An empty name never matches, so an account without one cannot sign in by it.
const sameName = (stored, typed) => {
  const key = nameKey(stored);
  return key !== '' && key === nameKey(typed);
};

module.exports = { nameKey, sameName };
