const test = require('node:test');
const assert = require('node:assert/strict');
const { parseUpcomingLimit, DEFAULT_UPCOMING_LIMIT, MAX_UPCOMING_LIMIT } = require('../services/upcomingLimit');

test('Today keeps its short list when no limit is asked for', () => {
    assert.equal(parseUpcomingLimit(undefined), DEFAULT_UPCOMING_LIMIT);
    assert.equal(DEFAULT_UPCOMING_LIMIT, 12);
});

test('the Calendar can ask for a longer list', () => {
    assert.equal(parseUpcomingLimit('50'), 50);
    assert.equal(parseUpcomingLimit(50), 50);
});

test('a limit above the cap is cut back to the cap', () => {
    assert.equal(parseUpcomingLimit('9999'), MAX_UPCOMING_LIMIT);
});

test('nonsense limits fall back to the default', () => {
    for (const bad of ['abc', '', '0', '-5', null, [], {}]) {
        assert.equal(parseUpcomingLimit(bad), DEFAULT_UPCOMING_LIMIT, `value ${JSON.stringify(bad)}`);
    }
});
