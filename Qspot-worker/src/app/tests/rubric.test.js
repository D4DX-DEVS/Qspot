const test = require('node:test');
const assert = require('node:assert/strict');
const { normalizeRubric, rubricTotal, markFromRequest, scoreFromRubric } = require('../services/rubric');

const parts = [{ label: 'Makharij', maxPoints: 4 }, { label: 'Madd length', maxPoints: 4 }, { label: 'Fluency', maxPoints: 2 }];
const byParts = { maxPoints: 10, rubric: { enabled: true, criteria: parts } };
const oneMark = { maxPoints: 10, rubric: { enabled: false, criteria: parts } };

test('marking by parts is off unless switched on', () => {
    assert.deepEqual(normalizeRubric(undefined), { enabled: false, criteria: [] });
    assert.deepEqual(normalizeRubric({ enabled: true, criteria: parts }), { enabled: true, criteria: parts });
    assert.equal(rubricTotal({ criteria: parts }), 10);
});

test('switching it off keeps the parts for later', () => {
    assert.deepEqual(normalizeRubric({ enabled: false, criteria: parts }).criteria, parts);
    assert.deepEqual(normalizeRubric(undefined, { enabled: true, criteria: parts }), { enabled: true, criteria: parts });
});

test('bad parts are refused', () => {
    assert.throws(() => normalizeRubric({ enabled: true, criteria: [] }), /at least one part/);
    assert.throws(() => normalizeRubric({ enabled: true, criteria: [{ label: '', maxPoints: 2 }] }), /name/);
    assert.throws(() => normalizeRubric({ enabled: true, criteria: [{ label: 'A', maxPoints: 1.5 }] }), /whole number/);
    assert.throws(() => normalizeRubric({ enabled: true, criteria: Array.from({ length: 9 }, (_, i) => ({ label: `P${i}`, maxPoints: 1 })) }), /at most 8/);
});

test('marked by parts: the mark is the sum of the parts', () => {
    const mark = markFromRequest(byParts, { rubricScores: [3, { points: 2 }, 2] });
    assert.equal(mark.grade, 7);
    assert.deepEqual(mark.rubricScores.map((s) => [s.label, s.points, s.maxPoints]), [['Makharij', 3, 4], ['Madd length', 2, 4], ['Fluency', 2, 2]]);
});

test('marked by parts: one number alone is refused, every part must be scored', () => {
    assert.throws(() => markFromRequest(byParts, { grade: 7 }), /part by part/);
    assert.throws(() => scoreFromRubric(byParts.rubric, [3, 2]), /every part/);
    assert.throws(() => scoreFromRubric(byParts.rubric, [5, 2, 2]), /between 0 and 4/);
    assert.equal(markFromRequest(byParts, { feedback: 'x' }), null);
});

test('marked as one: works as before and ignores parts', () => {
    assert.deepEqual(markFromRequest(oneMark, { grade: 8 }), { grade: 8, rubricScores: [] });
    assert.throws(() => markFromRequest(oneMark, { grade: 11 }), /between 0 and 10/);
    assert.equal(markFromRequest(oneMark, {}), null);
});
