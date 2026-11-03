const test = require('node:test');
const assert = require('node:assert/strict');
const { practiceOpen, retakeUpdate } = require('../services/practiceRetake');

const at = (iso) => new Date(iso);
const now = at('2026-10-15T12:00:00Z');
const attempt = (percentage, score) => ({
    answers: [{ questionId: 'q1', attemptedAnswer: '0', isCorrect: score > 0 }],
    score,
    totalQuestions: 5,
    percentage,
    language: 'English'
});

test('practice is open unless switched off or outside its dates', () => {
    assert.equal(practiceOpen({}, now), true);
    assert.equal(practiceOpen({ practiceEnabled: false }, now), false);
    assert.equal(practiceOpen({ practiceStartDate: at('2026-10-16T00:00:00Z') }, now), false);
    assert.equal(practiceOpen({ practiceEndDate: at('2026-10-14T00:00:00Z') }, now), false);
    assert.equal(practiceOpen({ practiceEndDate: at('2026-10-15T12:00:00Z') }, now), true);
    assert.equal(practiceOpen(null, now), false);
});

test('a better try replaces the best and counts', () => {
    const { improved, set } = retakeUpdate({ percentage: 60, attemptCount: 2 }, attempt(80, 4), now);
    assert.equal(improved, true);
    assert.equal(set.attemptCount, 3);
    assert.equal(set.percentage, 80);
    assert.equal(set.score, 4);
    assert.equal(set.lastPercentage, 80);
    assert.deepEqual(set.lastAttemptAt, now);
});

test('a worse or equal try keeps the best and still counts', () => {
    for (const pct of [40, 60]) {
        const { improved, set } = retakeUpdate({ percentage: 60, attemptCount: 1 }, attempt(pct, pct / 20), now);
        assert.equal(improved, false);
        assert.equal(set.attemptCount, 2);
        assert.equal(set.lastPercentage, pct);
        assert.equal('percentage' in set, false);
        assert.equal('answers' in set, false);
    }
});

test('rows saved before retakes existed count as one try', () => {
    const { set } = retakeUpdate({ percentage: 20 }, attempt(40, 2), now);
    assert.equal(set.attemptCount, 2);
});
