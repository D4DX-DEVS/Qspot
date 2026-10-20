const test = require('node:test');
const assert = require('node:assert/strict');
const { newUserFields, TEACHER_CLASS } = require('../services/newUser');

const PROFILE_ID = '6909a18e536ff7e1084ece97';

test('a student needs a name, phone and class', () => {
    const { fields, error } = newUserFields({ name: '  Ramu K ', phone: '+91 98765 43210', class: ' 9 ', email: ' a@b.co ' });
    assert.equal(error, undefined);
    assert.deepEqual(fields, { role: 'student', name: 'Ramu K', phone: '9876543210', email: 'a@b.co', class: '9' });
});

test('a student is the default when no role is sent', () => {
    assert.equal(newUserFields({ name: 'Ramu', phone: '9876543210', class: '9' }).fields.role, 'student');
});

test('a student without a class is refused', () => {
    assert.equal(newUserFields({ name: 'Ramu', phone: '9876543210', class: '  ' }).error, 'Class is required');
});

test('a short name or a bad phone is refused', () => {
    assert.equal(newUserFields({ name: 'Ra', phone: '9876543210', class: '9' }).error, 'Name must be at least 3 characters');
    assert.match(newUserFields({ name: 'Ramu', phone: '12345', class: '9' }).error, /valid/);
    assert.match(newUserFields({ name: 'Ramu', class: '9' }).error, /valid|required/i);
});

test('only students and teachers can be made here', () => {
    assert.equal(newUserFields({ role: 'admin', name: 'Ramu', phone: '9876543210', class: '9' }).error, 'Choose student or teacher');
});

test('a teacher needs a date of birth and a Speakers profile', () => {
    const { fields, error } = newUserFields({
        role: 'faculty', name: 'Suhaib CT', phone: '+44 07400 123456', dob: '1980-05-17', facultyProfile: PROFILE_ID
    });
    assert.equal(error, undefined);
    assert.equal(fields.role, 'faculty');
    assert.equal(fields.phone, '+447400123456');
    assert.equal(fields.class, TEACHER_CLASS);
    assert.equal(fields.facultyProfile, PROFILE_ID);
    assert.equal(fields.dob.toISOString(), '1980-05-17T00:00:00.000Z');
});

test('a teacher class typed in the form is ignored', () => {
    const { fields } = newUserFields({ role: 'faculty', name: 'Suhaib', phone: '9876543210', class: '9', dob: '1980-05-17', facultyProfile: PROFILE_ID });
    assert.equal(fields.class, TEACHER_CLASS);
});

test('a teacher without a real date of birth is refused', () => {
    for (const dob of [undefined, '', '17-05-1980', '1980-02-31', '2999-01-01']) {
        assert.match(newUserFields({ role: 'faculty', name: 'Suhaib', phone: '9876543210', dob, facultyProfile: PROFILE_ID }).error, /Date of birth/, String(dob));
    }
});

test('a teacher without a Speakers profile is refused', () => {
    for (const facultyProfile of [undefined, '', 'not-an-id']) {
        assert.equal(
            newUserFields({ role: 'faculty', name: 'Suhaib', phone: '9876543210', dob: '1980-05-17', facultyProfile }).error,
            'Choose the teacher profile from Speakers'
        );
    }
});
