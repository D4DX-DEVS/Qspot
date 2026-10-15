const test = require('node:test');
const assert = require('node:assert/strict');
const { reportError, pickReporter, reporters } = require('../services/errorReporter');

const quietly = (fn) => {
    const original = console.error;
    console.error = () => {};
    try { return fn(); } finally { console.error = original; }
};

test('no reporter is chosen by default, and unknown names fall back to none', () => {
    assert.equal(pickReporter(undefined), reporters.none);
    assert.equal(pickReporter('  NONE '), reporters.none);
    assert.equal(pickReporter('not-a-service'), reporters.none);
});

test('errors reach the chosen reporter with their context', () => {
    const seen = [];
    const fake = { captureException: (error, context) => seen.push({ error, context }) };
    const error = new Error('boom');
    quietly(() => reportError(error, { path: '/api/x' }, fake));
    assert.equal(seen.length, 1);
    assert.equal(seen[0].error, error);
    assert.equal(seen[0].context.path, '/api/x');
});

test('a broken reporter never throws', () => {
    const broken = { captureException: () => { throw new Error('reporter down'); } };
    assert.doesNotThrow(() => quietly(() => reportError(new Error('boom'), {}, broken)));
});
