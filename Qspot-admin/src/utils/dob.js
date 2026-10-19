// Date of birth in the Users page. It is how a teacher signs in to the app
// (students use their class), so the form explains what a change does. The server checks the
// same limits (Qspot-API/services/dob.js).

// A saved date (ISO string from the API) as the YYYY-MM-DD a date box uses.
export const dobInputValue = (saved) => {
  if (!saved) return '';
  const date = new Date(saved);
  return Number.isNaN(date.getTime()) ? '' : date.toISOString().slice(0, 10);
};

// Today back to 100 years ago, like the server.
export const dobInputLimits = (now = new Date()) => {
  const max = now.toISOString().slice(0, 10);
  return { min: `${now.getUTCFullYear() - 100}-01-01`, max };
};

// The line under the date box: what saving will mean for signing in.
export const dobHint = (saved, value) => {
  const savedValue = dobInputValue(saved);
  if (!savedValue && !value) return { text: "Can't sign in to the app until a date of birth is added.", warn: true };
  if (!savedValue) return { text: 'They will sign in with this date.', warn: false };
  if (value && value !== savedValue) return { text: 'They will sign in with the new date from now on.', warn: true };
  return { text: 'Used to sign in. Change it only to correct a mistake.', warn: false };
};
