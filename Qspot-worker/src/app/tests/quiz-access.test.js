const test = require('node:test');
const assert = require('node:assert/strict');
const { isAccessible, completedVideoCheck } = require('../services/quizAccess');

const student = { id: 'u1', class: '8' };

test('the "finished a video?" lookup runs once for many quizzes', async () => {
    let lookups = 0;
    const check = completedVideoCheck(student, async () => { lookups += 1; return { _id: 'x' }; });
    const quizzes = Array.from({ length: 10 }, () => ({ conditions: { requireCompletedVideo: true } }));
    const access = await Promise.all(quizzes.map((quiz) => isAccessible(quiz, student, check)));
    assert.deepEqual(access, Array(10).fill(true));
    assert.equal(lookups, 1);
});

test('no lookup at all when no quiz needs a video', async () => {
    let lookups = 0;
    const check = completedVideoCheck(student, async () => { lookups += 1; return null; });
    assert.equal(await isAccessible({ conditions: {} }, student, check), true);
    assert.equal(lookups, 0);
});

test('a quiz needing a finished video is hidden without one', async () => {
    const check = completedVideoCheck(student, async () => null);
    assert.equal(await isAccessible({ conditions: { requireCompletedVideo: true } }, student, check), false);
});

test('class restrictions still apply', async () => {
    const check = completedVideoCheck(student, async () => null);
    assert.equal(await isAccessible({ allowedClasses: ['9'] }, student, check), false);
    assert.equal(await isAccessible({ allowedClasses: ['8', '9'] }, student, check), true);
    assert.equal(await isAccessible({ allowedClasses: [] }, student, check), true);
});
