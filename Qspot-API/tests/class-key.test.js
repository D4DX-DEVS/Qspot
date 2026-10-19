const test = require('node:test');
const assert = require('node:assert/strict');
const { classKey, sameClass } = require('../services/classKey');

test('a class written as on screen or with spaces is the same class', () => {
    for (const typed of ['8', ' 8 ', 'Class 8', 'class 8', 'CLASS8']) {
        assert.equal(sameClass('8', typed), true, typed);
    }
    assert.equal(sameClass('Class 10A', '10a'), true);
});

test('a different class never matches', () => {
    assert.equal(sameClass('8', '9'), false);
    assert.equal(sameClass('8', '18'), false);
    assert.equal(sameClass('10', '1'), false);
});

test('an empty class never matches, even another empty one', () => {
    assert.equal(sameClass('', ''), false);
    assert.equal(sameClass(null, undefined), false);
    assert.equal(sameClass('8', ''), false);
});

test('a named class keeps its name', () => {
    assert.equal(classKey('Hifz batch'), 'hifzbatch');
    assert.equal(classKey('Faculty'), 'faculty');
});
