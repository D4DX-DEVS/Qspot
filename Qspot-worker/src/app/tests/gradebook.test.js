const test = require('node:test');
const assert = require('node:assert/strict');
const { buildGradebook } = require('../services/gradebook');

const at = (iso) => new Date(iso);
const now = at('2026-10-15T12:00:00Z');

const learners = [{ _id: 'u1', name: 'Aisha', class: '7' }, { _id: 'u2', name: 'Hiba', class: '7' }];
const exams = [
    { _id: 'e1', title: 'Unit Test 1', endDate: at('2026-10-08T12:00:00Z') },
    { _id: 'e2', title: 'Unit Test 2', endDate: at('2026-10-20T12:00:00Z') }
];
const assignments = [
    { _id: 'a1', title: 'Recitation', maxPoints: 10, dueAt: at('2026-10-14T12:00:00Z') },
    { _id: 'a2', title: 'Worksheet', maxPoints: 20, dueAt: at('2026-10-30T12:00:00Z') }
];

const book = buildGradebook({
    learners,
    exams,
    assignments,
    attempts: [{ _id: 't1', userId: 'u1', quizId: 'e1', percentage: 70 }],
    submissions: [
        { _id: 's1', userId: 'u1', assignmentId: 'a1', status: 'graded', grade: 8, submittedAt: at('2026-10-13T12:00:00Z') },
        { _id: 's2', userId: 'u2', assignmentId: 'a1', status: 'late', grade: null, submittedAt: at('2026-10-15T09:00:00Z') }
    ],
    practiceByUser: new Map([['u1', 87.5]]),
    lessonsByUser: new Map([['u1', 14], ['u2', 9]]),
    lessonsTotal: 40,
    now
});

const row = (id) => book.rows.find((r) => r.learner.id === id);

test('one column per exam then per assignment', () => {
    assert.deepEqual(book.columns.map((c) => c.id), ['exam:e1', 'exam:e2', 'assignment:a1', 'assignment:a2']);
    assert.equal(book.columns[2].maxPoints, 10);
});

test('exam cells: a score, not sat once ended, pending while open', () => {
    assert.equal(row('u1').cells['exam:e1'].percent, 70);
    assert.equal(row('u1').cells['exam:e1'].attemptId, 't1');
    assert.equal(row('u2').cells['exam:e1'].status, 'not_sat');
    assert.equal(row('u2').cells['exam:e2'].status, 'pending');
});

test('assignment cells: marked, waiting for a mark (late), missing, not due', () => {
    assert.deepEqual(
        { status: row('u1').cells['assignment:a1'].status, value: row('u1').cells['assignment:a1'].value, percent: row('u1').cells['assignment:a1'].percent },
        { status: 'graded', value: 8, percent: 80 }
    );
    assert.equal(row('u2').cells['assignment:a1'].status, 'needs_mark');
    assert.equal(row('u2').cells['assignment:a1'].late, true);
    assert.equal(row('u2').cells['assignment:a1'].submissionId, 's2');
    assert.equal(row('u2').cells['assignment:a2'].status, 'pending');
    assert.equal(book.needsMarking, 1);
});

test('overall averages the exams and assignments that have a mark', () => {
    assert.equal(row('u1').overall, 75);
    assert.equal(row('u2').overall, null);
    assert.equal(row('u1').practiceAvg, 88);
    assert.equal(row('u2').practiceAvg, null);
});

test('class averages skip blanks', () => {
    assert.equal(book.averages['exam:e1'], 70);
    assert.equal(book.averages['exam:e2'], null);
    assert.equal(book.averages.lessonsDone, 11.5);
    assert.equal(book.averages.overall, 75);
    assert.equal(book.lessonsTotal, 40);
});

test('a missed assignment past its due date shows as not sent', () => {
    const late = buildGradebook({ learners: [learners[1]], exams: [], assignments: [assignments[0]], now });
    assert.equal(late.rows[0].cells['assignment:a1'].status, 'not_sent');
});
