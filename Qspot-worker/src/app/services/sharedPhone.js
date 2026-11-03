// One phone number can hold several accounts: brothers and sisters often
// share a parent's number. They are told apart by name, so the number + name
// pair must be unique; the same name twice on one number is refused. Names are
// compared like sign-in compares them (see services/nameKey).
const User = require('../models/user');
const { sameName } = require('./nameKey');

const isStudent = (user) => (user.role || 'student') === 'student';

// The student on this number whose name matches what was typed at sign-in.
const studentByName = (accounts, name) =>
  accounts.find((user) => isStudent(user) && sameName(user.name, name)) || null;

// The account already on this number with this name, if any. exceptId skips
// the account being edited.
const nameTakenOnPhone = async (phone, name, exceptId = null) => {
  const filter = exceptId ? { phone, _id: { $ne: exceptId } } : { phone };
  const accounts = await User.find(filter).select('name').lean();
  return accounts.find((user) => sameName(user.name, name)) || null;
};

module.exports = { isStudent, studentByName, nameTakenOnPhone };
