const test = require('node:test');
const assert = require('node:assert/strict');
const { nameKey, sameName } = require('../services/nameKey');

test('a name typed with other capitals or spaces is the same name', () => {
    for (const typed of ['ramu k', 'RaMu K', 'RAMUK', ' ramu  k ', 'Ramu\tK']) {
        assert.equal(sameName('ramu k', typed), true, typed);
    }
    assert.equal(nameKey('RaMu K'), 'ramuk');
});

test('a different name never matches, symbols included', () => {
    assert.equal(sameName('ramu k', 'ramu'), false);
    assert.equal(sameName('ramu k', 'ramu k.'), false, 'only spaces and capitals are ignored');
    assert.equal(sameName('ramu k', 'k ramu'), false, 'word order matters');
});

test('an empty name never matches, even another empty one', () => {
    assert.equal(sameName('', ''), false);
    assert.equal(sameName(null, undefined), false);
    assert.equal(sameName('ramu k', '   '), false);
});
