import { useState } from 'react';
import apiClient from '../api/client';

// Form state and saving for the Users page's Add User dialog. Students sign in
// with name + phone; teachers sign in with phone + date of birth and need
// their Speakers profile, so only the fields for the chosen kind are sent.
// The server checks the same rules (Qspot-API/services/newUser.js).

export const ROLE_OPTIONS = [
  { value: 'student', label: 'Student' },
  { value: 'faculty', label: 'Teacher' },
];

// Qspot is for classes 8 to 12 (STUDENT_CLASSES on the server).
const CLASS_MIN = 8;
const CLASS_MAX = 12;

// The class box keeps digits only (typed or pasted), at most two.
const classDigits = (typed) => String(typed).replace(/\D/g, '').slice(0, 2);

// The message under the class box, or '' when the class is fine. The server
// sends the same wording.
const classProblem = (value) => {
  if (!value) return `Enter the class (${CLASS_MIN} to ${CLASS_MAX}).`;
  const number = Number(value);
  return number < CLASS_MIN || number > CLASS_MAX ? `Class should be between ${CLASS_MIN} and ${CLASS_MAX}.` : '';
};

// "08" is saved as "8", like every other account.
const classValue = (typed) => (typed ? String(Number(typed)) : '');

const EMPTY_FORM = { role: 'student', name: '', phone: '', email: '', class: '', dob: '', facultyProfile: '' };

const payloadFor = (form) => {
  const shared = { role: form.role, name: form.name.trim(), phone: form.phone.trim(), email: form.email.trim() };
  return form.role === 'faculty'
    ? { ...shared, dob: form.dob, facultyProfile: form.facultyProfile }
    : { ...shared, class: classValue(form.class) };
};

const useAddUserForm = (onCreated) => {
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  // The class message waits until the box is left or Create is pressed, so
  // typing "1" on the way to "12" doesn't flash an error.
  const [classChecked, setClassChecked] = useState(false);

  const setField = (key, value) =>
    setForm((prev) => ({ ...prev, [key]: key === 'class' ? classDigits(value) : value }));

  const classError = form.role === 'student' ? classProblem(form.class) : '';

  const submit = async () => {
    if (classError) {
      setClassChecked(true);
      return;
    }
    setSaving(true);
    setError('');
    try {
      const { data } = await apiClient.post('/admin/users', payloadFor(form));
      onCreated(data.user);
    } catch (err) {
      setError(err.message || 'Failed to create user');
    } finally {
      setSaving(false);
    }
  };

  return {
    form,
    setField,
    saving,
    error,
    submit,
    isTeacher: form.role === 'faculty',
    classError: classChecked ? classError : '',
    checkClass: () => setClassChecked(true),
  };
};

export default useAddUserForm;
