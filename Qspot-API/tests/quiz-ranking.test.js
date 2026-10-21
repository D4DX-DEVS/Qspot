const test = require('node:test');
const assert = require('node:assert/strict');
const { withRanks } = require('../services/quizRanking');

const ranks = (attempts) => withRanks(attempts).map(({ rank }) => rank);

test('a higher score ranks first, then less time', () => {
    assert.deepEqual(ranks([
        { score: 9, totalDuration: 60 },
        { score: 9, totalDuration: 90 },
        { score: 7, totalDuration: 20 }
    ]), [1, 2, 3]);
});

test('the same score and the same time share a rank, and the next one is skipped', () => {
    assert.deepEqual(ranks([
        { score: 9, totalDuration: 60 },
        { score: 8, totalDuration: 30 },
        { score: 8, totalDuration: 30 },
        { score: 8, totalDuration: 45 },
        { score: 5, totalDuration: 10 },
        { score: 5, totalDuration: 10 },
        { score: 5, totalDuration: 10 }
    ]), [1, 2, 2, 4, 5, 5, 5]);
});

test('the same score in a different time is not a tie', () => {
    assert.deepEqual(ranks([{ score: 4, totalDuration: 30 }, { score: 4, totalDuration: 31 }]), [1, 2]);
});

test('a missing score or time counts as 0', () => {
    assert.deepEqual(ranks([{ score: 0, totalDuration: 0 }, {}]), [1, 1]);
});

test('no attempts, no ranks', () => {
    assert.deepEqual(ranks([]), []);
});
