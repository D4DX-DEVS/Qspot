const test = require('node:test');
const assert = require('node:assert/strict');
const { canShuffle, shuffledOrder, savedOrder, inShownOrder, storedIndex } = require('../services/optionOrder');

const QID = '64b000000000000000000001';
const session = (order) => ({ optionOrders: [{ questionId: QID, order }] });
const four = ['A', 'B', 'C', 'D'];

test('a shuffled order uses every position once', () => {
    for (let run = 0; run < 50; run++) {
        const order = shuffledOrder(4);
        assert.deepEqual([...order].sort(), [0, 1, 2, 3]);
    }
});

test('the order really changes from student to student', () => {
    const seen = new Set(Array.from({ length: 200 }, () => shuffledOrder(4).join('')));
    assert.ok(seen.size > 10);
});

test('multiple choice is shuffled; True / False and mismatched lists are not', () => {
    assert.equal(canShuffle('Multiple Choice', four, four), true);
    assert.equal(canShuffle('Multiple Choice', four, []), true);
    assert.equal(canShuffle('True / False', ['True', 'False'], ['ശരി', 'തെറ്റ്']), false);
    assert.equal(canShuffle('Multiple Choice', four, ['A', 'B', 'C']), false);
    assert.equal(canShuffle('Multiple Choice', ['A'], ['A']), false);
});

test('options are shown in the saved order and the tap maps back', () => {
    const order = savedOrder(session([2, 0, 3, 1]), QID, four, four);
    assert.deepEqual(inShownOrder(four, order), ['C', 'A', 'D', 'B']);
    // Tapping the first option shown ("C") is stored option 2.
    assert.equal(storedIndex(0, order), 2);
    assert.equal(storedIndex(3, order), 1);
});

test('no saved order, or one that no longer fits, uses the stored order', () => {
    assert.equal(savedOrder({}, QID, four, four), null);
    assert.equal(savedOrder(session([0, 1, 2]), QID, four, four), null);
    assert.equal(savedOrder(session([0, 0, 1, 2]), QID, four, four), null);
    assert.equal(savedOrder(session([0, 1, 2, 4]), QID, four, four), null);
    assert.equal(savedOrder(session([3, 2, 1, 0]), QID, four, ['A', 'B']), null);
    assert.deepEqual(inShownOrder(four, null), four);
    assert.equal(storedIndex(1, null), 1);
});

test('a position outside the list is left alone', () => {
    const order = [1, 0];
    assert.equal(storedIndex(-1, order), -1);
    assert.equal(storedIndex(5, order), 5);
});
