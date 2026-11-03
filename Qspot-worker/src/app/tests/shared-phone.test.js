const test = require('node:test');
const assert = require('node:assert/strict');
const { isStudent, studentByName } = require('../services/sharedPhone');

const sisters = [
    { _id: 'a', name: 'Nafisa shafees', role: 'student' },
    { _id: 'b', name: 'Mariyam shafees' },
    { _id: 'c', name: 'Shafees K', role: 'faculty' }
];

test('an account with no role is a student', () => {
    assert.equal(isStudent({}), true);
    assert.equal(isStudent({ role: 'student' }), true);
    assert.equal(isStudent({ role: 'faculty' }), false);
});

test('each student on a shared number signs in with their own name', () => {
    assert.equal(studentByName(sisters, 'Nafisa shafees')._id, 'a');
    assert.equal(studentByName(sisters, 'MARIYAM  SHAFEES')._id, 'b', 'spaces and capitals ignored');
});

test('a wrong name, a teacher name or an empty name signs nobody in', () => {
    assert.equal(studentByName(sisters, 'Fathima shafees'), null);
    assert.equal(studentByName(sisters, 'Shafees K'), null, 'a name never signs a teacher in');
    assert.equal(studentByName(sisters, ''), null);
    assert.equal(studentByName([], 'Nafisa shafees'), null);
});
