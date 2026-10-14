const test = require('node:test');
const assert = require('node:assert/strict');
const { assessTiming, STATUS } = require('../services/quizTiming');

const START = new Date('2026-10-14T10:00:00Z');
const perQuestion = { timerMode: 'per-question', perQuestionTimeLimit: 30 };
const overall = { timerMode: 'overall', overallTimeLimit: 60 };

const run = (config, entries, more = {}) => assessTiming({
    config,
    startedAt: START,
    receivedAt: new Date(START.getTime() + 600 * 1000),
    totalDuration: 120,
    entries,
    ...more
});
const took = (attemptedIndex, duration) => ({ attemptedIndex, submitted: { duration } });

test('an answer in time counts', () => {
    const { answers } = run(perQuestion, [took(2, 20)]);
    assert.equal(answers[0].status, STATUS.ANSWERED);
    assert.equal(answers[0].voided, false);
    assert.equal(answers[0].duration, 20);
});

test("an answer that took longer than the question's time is thrown out", () => {
    const { answers } = run(perQuestion, [took(2, 45)]);
    assert.equal(answers[0].status, STATUS.TIMED_OUT);
    assert.equal(answers[0].voided, true);
});

test('a little rounding at the limit is allowed', () => {
    assert.equal(run(perQuestion, [took(1, 32)]).answers[0].status, STATUS.ANSWERED);
});

test("answers after the whole quiz's time are thrown out", () => {
    const { answers } = run(overall, [took(0, 40), took(1, 15), took(2, 20)]);
    assert.deepEqual(answers.map((a) => a.status), [STATUS.ANSWERED, STATUS.ANSWERED, STATUS.TIMED_OUT]);
});

test('unanswered questions are timed out, skipped or not reached', () => {
    const { answers } = run(perQuestion, [took(null, 30), took(null, 12.4), took(null, 0)]);
    assert.deepEqual(answers.map((a) => a.status), [STATUS.TIMED_OUT, STATUS.SKIPPED, STATUS.NOT_REACHED]);
});

test('without a question limit an unanswered question is just skipped', () => {
    const { answers } = run(overall, [took(null, 50)]);
    assert.equal(answers[0].status, STATUS.SKIPPED);
});

test('no phone timestamps are needed, so a wrong phone clock changes nothing', () => {
    // Only durations are sent; the same answers give the same result
    // whatever time the phone thinks it is.
    const a = run(perQuestion, [took(1, 10), took(2, 25)]);
    const b = run(perQuestion, [took(1, 10), took(2, 25)], { receivedAt: new Date(START.getTime() + 36e5) });
    assert.deepEqual(a.answers, b.answers);
});

test('time taken is capped by the time the server saw pass', () => {
    const result = run(perQuestion, [took(1, 10)], {
        totalDuration: 9999,
        receivedAt: new Date(START.getTime() + 300 * 1000)
    });
    assert.equal(result.totalDuration, 300);
});

test('an older app without timing keeps its answers unchecked', () => {
    const { answers, hasTimingData } = run(perQuestion, [
        { attemptedIndex: 1, submitted: { questionId: 'a', attemptedAnswer: 1 } },
        { attemptedIndex: null, submitted: { questionId: 'b', attemptedAnswer: null } }
    ]);
    assert.equal(hasTimingData, false);
    assert.equal(answers[0].status, STATUS.ANSWERED);
    assert.equal(answers[1].status, undefined);
    assert.equal(answers[0].voided, false);
});

test('garbage durations are read as zero', () => {
    const { answers } = run(perQuestion, [took(1, 'x'), took(null, -4)]);
    assert.equal(answers[0].duration, 0);
    assert.equal(answers[0].status, STATUS.ANSWERED);
    assert.equal(answers[1].status, STATUS.NOT_REACHED);
});
