// Checks the Add User form from the admin panel. Students sign in with name +
// phone and teachers with phone + date of birth, and a teacher's screens only
// work when the account is linked to their Speakers profile, so each kind of
// account needs different fields. Returns the account to save, or the message
// to show the admin.
const mongoose = require('mongoose');
const { normalizePhone, phoneError } = require('./phone');
const { parseDob } = require('./dob');

const ROLES = ['student', 'faculty'];
// Every account needs a class; teachers aren't in one.
const TEACHER_CLASS = 'Teacher';

const newUserFields = (body = {}) => {
  const role = body.role || 'student';
  if (!ROLES.includes(role)) return { error: 'Choose student or teacher' };

  const name = String(body.name ?? '').trim();
  if (name.length < 3) return { error: 'Name must be at least 3 characters' };

  // Saved the way sign-in looks it up, or they could not sign in.
  const phone = normalizePhone(String(body.phone ?? ''));
  const phoneProblem = phoneError(phone);
  if (phoneProblem) return { error: phoneProblem };

  const email = String(body.email ?? '').trim();

  if (role === 'student') {
    const userClass = String(body.class ?? '').trim();
    if (!userClass) return { error: 'Class is required' };
    return { fields: { role, name, phone, email, class: userClass } };
  }

  const dob = parseDob(body.dob);
  if (!dob) return { error: 'Date of birth must be a real date (YYYY-MM-DD), not in the future' };

  const facultyProfile = String(body.facultyProfile ?? '');
  if (!mongoose.Types.ObjectId.isValid(facultyProfile)) {
    return { error: 'Choose the teacher profile from Speakers' };
  }
  return { fields: { role, name, phone, email, class: TEACHER_CLASS, dob, facultyProfile } };
};

module.exports = { newUserFields, TEACHER_CLASS };
