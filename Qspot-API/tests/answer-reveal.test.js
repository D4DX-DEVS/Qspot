const test = require('node:test');
const assert = require('node:assert/strict');
const { examAnswersAt, practiceAnswersAt, answersRevealed, revealFields } = require('../services/answerReveal');

const MINUTE = 60 * 1000;
const at = (iso) => new Date(iso);
const results = [{ questionId: 'q1', correctAnswer: 2 }];

test('exam answers show once the grace period after the end date is over', () => {
    const config = { endDate: at('2026-10-15T19:00:00Z') };
    const availableAt = examAnswersAt(config, 5 * MINUTE);
    assert.deepEqual(availableAt, at('2026-10-15T19:05:00Z'));
    assert.equal(answersRevealed(availableAt, at('2026-10-15T19:04:59Z')), false);
    assert.equal(answersRevealed(availableAt, at('2026-10-15T19:05:00Z')), true);
});

test('an exam with no end date never reveals answers', () => {
    assert.equal(examAnswersAt({}, 5 * MINUTE), null);
    assert.equal(examAnswersAt({ endDate: 'not a date' }, 5 * MINUTE), null);
    assert.equal(answersRevealed(null, at('2030-01-01T00:00:00Z')), false);
});

test('practice answers show at the practice end date, never without one', () => {
    assert.deepEqual(practiceAnswersAt({ practiceEndDate: at('2026-10-20T00:00:00Z') }), at('2026-10-20T00:00:00Z'));
    assert.equal(practiceAnswersAt({ practiceEndDate: null }), null);
    assert.equal(practiceAnswersAt(null), null);
});

test('results are withheld until revealed', () => {
    const availableAt = at('2026-10-15T19:05:00Z');
    assert.deepEqual(revealFields(availableAt, results, at('2026-10-15T18:00:00Z')), {
        answersRevealed: false,
        answersAvailableAt: availableAt,
        results: []
    });
    assert.deepEqual(revealFields(availableAt, results, at('2026-10-15T20:00:00Z')), {
        answersRevealed: true,
        answersAvailableAt: availableAt,
        results
    });
    assert.deepEqual(revealFields(null, results, at('2026-10-15T20:00:00Z')).results, []);
});
