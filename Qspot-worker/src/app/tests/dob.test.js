const test = require('node:test');
const assert = require('node:assert/strict');
const { parseDob, dobKey, sameDob } = require('../services/dob');

const NOW = new Date('2026-10-14T10:00:00Z');

test('a plain YYYY-MM-DD date is read as UTC midnight', () => {
    const date = parseDob('2010-05-03', NOW);
    assert.equal(date.toISOString(), '2010-05-03T00:00:00.000Z');
    assert.equal(dobKey(date), '2010-05-03');
});

test('a date that does not exist is refused', () => {
    for (const bad of ['2010-02-31', '2010-13-01', '2010-00-10', '2010-04-31']) {
        assert.equal(parseDob(bad, NOW), null, bad);
    }
    assert.notEqual(parseDob('2008-02-29', NOW), null, 'leap day');
    assert.equal(parseDob('2010-02-29', NOW), null, 'not a leap year');
});

test('anything that is not YYYY-MM-DD is refused', () => {
    for (const bad of ['', null, undefined, '03-05-2010', '2010/05/03', '2010-5-3', 'abc', '2010-05-03T00:00:00Z', 20100503, []]) {
        assert.equal(parseDob(bad, NOW), null, `value ${JSON.stringify(bad)}`);
    }
});

test('a date in the future is refused, today is allowed', () => {
    assert.equal(parseDob('2026-10-15', NOW), null);
    assert.notEqual(parseDob('2026-10-14', NOW), null);
});

test('a date more than 100 years back is refused', () => {
    assert.equal(parseDob('1925-01-01', NOW), null);
    assert.notEqual(parseDob('1926-01-01', NOW), null);
});

test('surrounding spaces do not matter', () => {
    assert.notEqual(parseDob(' 2010-05-03 ', NOW), null);
});

test('sameDob matches the same calendar day only', () => {
    const stored = new Date('2010-05-03T00:00:00Z');
    assert.equal(sameDob(stored, parseDob('2010-05-03', NOW)), true);
    assert.equal(sameDob(stored, parseDob('2010-05-04', NOW)), false);
    assert.equal(sameDob(stored, parseDob('2011-05-03', NOW)), false);
});

test('an account with no stored date never matches', () => {
    const parsed = parseDob('2010-05-03', NOW);
    assert.equal(sameDob(null, parsed), false);
    assert.equal(sameDob(undefined, parsed), false);
    assert.equal(sameDob(null, null), false);
});
