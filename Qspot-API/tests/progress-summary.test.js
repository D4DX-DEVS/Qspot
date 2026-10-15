const test = require('node:test');
const assert = require('node:assert/strict');
const { buildProgressSummary } = require('../services/progressSummary');
const { subjectScopeFilter, isScopedLearner } = require('../services/learnerScope');

const NOW = new Date('2026-10-13T10:00:00Z');

const lessons = (subject, count, startAt = 0) =>
    Array.from({ length: count }, (_, i) => ({ _id: `${subject}-v${startAt + i}`, subject }));

test('one finished lesson out of forty is not 100%', () => {
    const subjects = [
        { _id: 's1', name: 'Letters', courseId: 'c1' },
        { _id: 's2', name: 'Madd', courseId: 'c1' }
    ];
    const videos = [...lessons('s1', 20), ...lessons('s2', 20)];
    const progressRows = [{ videoId: 's1-v0', completed: true }];

    const summary = buildProgressSummary({ subjects, videos, progressRows, courseTitles: new Map([['c1', 'Tajweed']]), now: NOW });

    assert.deepEqual(summary.videos, { total: 40, completed: 1, inProgress: 0 });
    assert.deepEqual(summary.courses, [{ courseId: 'c1', title: 'Tajweed', total: 40, completed: 1 }]);
    assert.deepEqual(summary.subjects.map((s) => [s.name, s.total, s.completed]), [['Letters', 20, 1], ['Madd', 20, 0]]);
});

test('lessons that open later are not counted', () => {
    const subjects = [{ _id: 's1', name: 'Letters', courseId: null }];
    const videos = [
        ...lessons('s1', 3),
        { _id: 's1-future', subject: 's1', releaseDate: '2026-11-01T00:00:00Z' },
        { _id: 's1-past', subject: 's1', releaseDate: '2026-09-01T00:00:00Z' }
    ];

    const summary = buildProgressSummary({ subjects, videos, progressRows: [], now: NOW });

    assert.equal(summary.videos.total, 4);
    assert.deepEqual(summary.courses, []);
});

test('progress on lessons outside the learner scope is ignored', () => {
    const subjects = [{ _id: 's1', name: 'Letters', courseId: 'c1' }];
    const videos = lessons('s1', 2);
    const progressRows = [
        { videoId: 's1-v0', completed: true },
        { videoId: 'left-course-v0', completed: true }
    ];

    const summary = buildProgressSummary({ subjects, videos, progressRows, now: NOW });

    assert.deepEqual(summary.videos, { total: 2, completed: 1, inProgress: 0 });
});

test('started but unfinished lessons count as in progress', () => {
    const subjects = [{ _id: 's1', name: 'Letters', courseId: 'c1' }];
    const videos = lessons('s1', 4);
    const progressRows = [
        { videoId: 's1-v0', completed: true },
        { videoId: 's1-v1', completed: false, watchedSeconds: 30 },
        { videoId: 's1-v2', completed: false, positionSeconds: 12 },
        { videoId: 's1-v3', completed: false, watchedSeconds: 0, positionSeconds: 0 }
    ];

    const summary = buildProgressSummary({ subjects, videos, progressRows, now: NOW });

    assert.deepEqual(summary.videos, { total: 4, completed: 1, inProgress: 2 });
});

test('chapters with no lessons are left out and course totals add up', () => {
    const subjects = [
        { _id: 's1', name: 'Letters', courseId: 'c1' },
        { _id: 's2', name: 'Empty', courseId: 'c1' },
        { _id: 's3', name: 'Purification', courseId: 'c2' }
    ];
    const videos = [...lessons('s1', 2), ...lessons('s3', 3)];
    const progressRows = [{ videoId: 's1-v0', completed: true }, { videoId: 's3-v1', completed: true }];

    const summary = buildProgressSummary({
        subjects,
        videos,
        progressRows,
        courseTitles: new Map([['c1', 'Tajweed'], ['c2', 'Fiqh Basics']]),
        now: NOW
    });

    assert.deepEqual(summary.subjects.map((s) => s.name), ['Letters', 'Purification']);
    assert.deepEqual(summary.courses.map((c) => [c.title, c.total, c.completed]), [['Tajweed', 2, 1], ['Fiqh Basics', 3, 1]]);
});

test('a learner with no chosen course matches no chapter', () => {
    const none = { isPublished: { $ne: false }, courseId: { $in: [] } };
    assert.deepEqual(subjectScopeFilter([]), none);
    assert.deepEqual(subjectScopeFilter(undefined), none);
});

test('only signed-in students are narrowed to their courses', () => {
    assert.equal(isScopedLearner({ userId: 'u1', role: 'student' }), true);
    assert.equal(isScopedLearner({ userId: 'u1', role: 'admin' }), false);
    assert.equal(isScopedLearner({ userId: 'u1', role: 'faculty' }), false);
    assert.equal(isScopedLearner({ role: 'student' }), false);
    assert.equal(isScopedLearner(undefined), false);
});

test('a course list narrows chapters to those courses', () => {
    assert.deepEqual(subjectScopeFilter(['c1', 'c2']), {
        isPublished: { $ne: false },
        courseId: { $in: ['c1', 'c2'] }
    });
});
