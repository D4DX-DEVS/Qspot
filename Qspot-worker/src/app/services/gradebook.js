// The admin gradebook: one row per learner, one column per exam and per
// assignment, plus practice and lessons. Built from rows the route has
// already fetched, so it can be tested without a database.
//
// Cell status:
//   exam:       done | not_sat (ended, no attempt) | pending (still open)
//   assignment: graded | needs_mark | returned | not_sent (past due, nothing
//               sent) | pending (not due yet, nothing sent)

const percentOf = (value, max) => (max > 0 ? Math.round((value / max) * 100) : null);

const mean = (values) => {
    const numbers = values.filter((v) => typeof v === 'number' && Number.isFinite(v));
    return numbers.length ? Math.round(numbers.reduce((a, b) => a + b, 0) / numbers.length) : null;
};

const isPast = (date, now) => Boolean(date) && new Date(date).getTime() < now.getTime();

const examCell = (exam, attempt, now) => {
    if (attempt) {
        return { value: attempt.percentage, percent: attempt.percentage, status: 'done', attemptId: String(attempt._id) };
    }
    return { value: null, percent: null, status: isPast(exam.endDate, now) ? 'not_sat' : 'pending' };
};

const assignmentCell = (assignment, submission, now) => {
    if (!submission) {
        return { value: null, percent: null, status: isPast(assignment.dueAt, now) ? 'not_sent' : 'pending' };
    }
    const late = Boolean(assignment.dueAt) && new Date(submission.submittedAt) > new Date(assignment.dueAt);
    const base = { submissionId: String(submission._id), late };
    if (submission.status === 'graded' && submission.grade !== null && submission.grade !== undefined) {
        return { ...base, value: submission.grade, percent: percentOf(submission.grade, assignment.maxPoints), status: 'graded' };
    }
    if (submission.status === 'returned') return { ...base, value: null, percent: null, status: 'returned' };
    return { ...base, value: null, percent: null, status: 'needs_mark' };
};

const pairKey = (a, b) => `${String(a)}:${String(b)}`;

const buildGradebook = ({
    learners,
    exams,
    assignments,
    attempts = [],
    submissions = [],
    practiceByUser = new Map(),
    lessonsByUser = new Map(),
    lessonsTotal = 0,
    now = new Date()
}) => {
    const attemptMap = new Map(attempts.map((a) => [pairKey(a.userId, a.quizId), a]));
    const submissionMap = new Map(submissions.map((s) => [pairKey(s.userId, s.assignmentId), s]));
    const columns = [
        ...exams.map((e) => ({ id: `exam:${e._id}`, kind: 'exam', refId: String(e._id), title: e.title, date: e.endDate || null })),
        ...assignments.map((a) => ({
            id: `assignment:${a._id}`, kind: 'assignment', refId: String(a._id), title: a.title, maxPoints: a.maxPoints, date: a.dueAt || null
        }))
    ];

    let needsMarking = 0;
    const rows = learners.map((learner) => {
        const id = String(learner._id);
        const cells = {};
        exams.forEach((e) => {
            cells[`exam:${e._id}`] = examCell(e, attemptMap.get(pairKey(id, e._id)), now);
        });
        assignments.forEach((a) => {
            const cell = assignmentCell(a, submissionMap.get(pairKey(id, a._id)), now);
            if (cell.status === 'needs_mark') needsMarking += 1;
            cells[`assignment:${a._id}`] = cell;
        });
        return {
            learner: { id, name: learner.name || '', class: learner.class || '' },
            cells,
            practiceAvg: practiceByUser.has(id) ? Math.round(practiceByUser.get(id)) : null,
            lessonsDone: lessonsByUser.get(id) || 0,
            // Exams and assignments count equally; nothing sat or marked yet = no overall.
            overall: mean(Object.values(cells).map((cell) => cell.percent))
        };
    });

    const averages = {};
    columns.forEach((column) => {
        averages[column.id] = mean(rows.map((row) => row.cells[column.id].percent));
    });
    averages.practiceAvg = mean(rows.map((row) => row.practiceAvg));
    averages.lessonsDone = rows.length
        ? Math.round((rows.reduce((sum, row) => sum + row.lessonsDone, 0) / rows.length) * 10) / 10
        : null;
    averages.overall = mean(rows.map((row) => row.overall));

    return { columns, rows, averages, lessonsTotal, needsMarking };
};

module.exports = { buildGradebook, examCell, assignmentCell };
