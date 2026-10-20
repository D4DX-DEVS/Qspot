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

const EMPTY_FORM = { role: 'student', name: '', phone: '', email: '', class: '', dob: '', facultyProfile: '' };

const payloadFor = (form) => {
  const shared = { role: form.role, name: form.name.trim(), phone: form.phone.trim(), email: form.email.trim() };
  return form.role === 'faculty'
    ? { ...shared, dob: form.dob, facultyProfile: form.facultyProfile }
    : { ...shared, class: form.class.trim() };
};

const useAddUserForm = (onCreated) => {
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const setField = (key, value) => setForm((prev) => ({ ...prev, [key]: value }));

  const submit = async () => {
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

  return { form, setField, saving, error, submit, isTeacher: form.role === 'faculty' };
};

export default useAddUserForm;
