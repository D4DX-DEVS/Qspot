// The account as the app sees it (sign-in, profile, saving a date of birth).
// Shared by the student and faculty routes so both send the same shape.
const publicUser = (user) => ({
  id: user._id,
  name: user.name,
  phone: user.phone,
  class: user.class,
  courseIds: (user.courseIds || []).map((id) => String(id)),
  email: user.email || '',
  profileImage: user.profileImage || '',
  role: user.role || 'student',
  dob: user.dob || null,
  phoneVerified: user.phoneVerified !== false,
  consent: user.consent && user.consent.by ? user.consent : null,
  language: user.language || 'en'
});

module.exports = { publicUser };
