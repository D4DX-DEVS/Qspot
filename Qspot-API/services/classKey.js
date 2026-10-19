// A student's class is their sign-in check, so it is compared in exactly one
// way: "8", " 8 ", "Class 8" and "class 8" are the same class.
const classKey = (value) => String(value ?? '')
  .trim()
  .replace(/^class\s*(?=\d)/i, '')
  .replace(/\s+/g, '')
  .toLowerCase();

// An empty class never matches, so an account with none cannot sign in by it.
const sameClass = (stored, typed) => {
  const key = classKey(stored);
  return key !== '' && key === classKey(typed);
};

module.exports = { classKey, sameClass };
