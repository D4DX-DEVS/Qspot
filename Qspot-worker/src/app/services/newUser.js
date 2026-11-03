// Checks the Add User form from the admin panel. Students sign in with name +
// phone and teachers with phone + date of birth, and a teacher's screens only
// work when the account is linked to their Speakers profile, so each kind of
// account needs different fields. Returns the account to save, or the message
// to show the admin.
const mongoose = require('mongoose');
const { normalizePhone, phoneError } = require('./phone');
const { parseDob } = require('./dob');

const ROLES = ['student', 'faculty'];
// Qspot is for classes 8 to 12; the admin form offers the same list.
const STUDENT_CLASSES = ['8', '9', '10', '11', '12'];
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
    if (!STUDENT_CLASSES.includes(userClass)) return { error: 'Class should be between 8 and 12.' };
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

module.exports = { newUserFields, STUDENT_CLASSES, TEACHER_CLASS };
