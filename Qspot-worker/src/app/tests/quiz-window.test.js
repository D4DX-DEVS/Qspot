const test = require('node:test');
const assert = require('node:assert/strict');
const { submitGraceMs, submissionWindow, DEFAULT_GRACE_MINUTES } = require('../services/quizWindow');

const MINUTE = 60 * 1000;
const at = (iso) => new Date(iso);
const config = (overrides = {}) => ({
    isEnable: true,
    startDate: at('2026-10-14T10:00:00Z'),
    endDate: at('2026-10-14T11:00:00Z'),
    ...overrides
});

test('a live quiz is open', () => {
    assert.equal(submissionWindow(config(), at('2026-10-14T10:30:00Z'), 5 * MINUTE), 'open');
    assert.equal(submissionWindow(config(), at('2026-10-14T11:00:00Z'), 5 * MINUTE), 'open');
});

test('a quiz that has not started, or is switched off, is closed', () => {
    assert.equal(submissionWindow(config(), at('2026-10-14T09:59:00Z'), 5 * MINUTE), 'closed');
    assert.equal(submissionWindow(config({ isEnable: false }), at('2026-10-14T10:30:00Z'), 5 * MINUTE), 'closed');
});

test('just after the end it is in grace, then too late', () => {
    assert.equal(submissionWindow(config(), at('2026-10-14T11:04:59Z'), 5 * MINUTE), 'grace');
    assert.equal(submissionWindow(config(), at('2026-10-14T11:05:00Z'), 5 * MINUTE), 'grace');
    assert.equal(submissionWindow(config(), at('2026-10-14T11:05:01Z'), 5 * MINUTE), 'ended');
});

test('no grace means too late the moment the quiz ends', () => {
    assert.equal(submissionWindow(config(), at('2026-10-14T11:00:01Z'), 0), 'ended');
});

test('a switched-off quiz stays closed even after its end', () => {
    assert.equal(submissionWindow(config({ isEnable: false }), at('2026-10-14T12:00:00Z'), 0), 'closed');
});

test('grace period comes from QUIZ_SUBMIT_GRACE_MINUTES, default 5, bad values mean none', () => {
    assert.equal(DEFAULT_GRACE_MINUTES, 5);
    assert.equal(submitGraceMs({}), 5 * MINUTE);
    assert.equal(submitGraceMs({ QUIZ_SUBMIT_GRACE_MINUTES: '10' }), 10 * MINUTE);
    assert.equal(submitGraceMs({ QUIZ_SUBMIT_GRACE_MINUTES: '0' }), 0);
    for (const bad of ['abc', '-3', '']) {
        assert.equal(submitGraceMs({ QUIZ_SUBMIT_GRACE_MINUTES: bad }), 0, `value ${JSON.stringify(bad)}`);
    }
});
