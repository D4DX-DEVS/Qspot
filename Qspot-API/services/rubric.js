// Marking by parts ("rubric"), switched on per assignment. When on, the
// assignment lists its parts (e.g. "Makharij" out of 4) and its total is the
// sum of the parts; a teacher scores each part and the mark is the sum.
// When off, the assignment is marked with one number as before.

const MAX_PARTS = 8;

const fail = (message) => Object.assign(new Error(message), { status: 400 });

// -> { enabled, criteria: [{ label, maxPoints }] }. The parts are kept when
// the switch is turned off, so turning it back on restores them.
const normalizeRubric = (input, existing = null) => {
    if (input === undefined) {
        return existing
            ? { enabled: Boolean(existing.enabled), criteria: (existing.criteria || []).map((c) => ({ label: c.label, maxPoints: c.maxPoints })) }
            : { enabled: false, criteria: [] };
    }
    if (input === null || typeof input !== 'object' || Array.isArray(input)) throw fail('rubric must be an object');
    const enabled = input.enabled === true || input.enabled === 'true';
    const raw = Array.isArray(input.criteria) ? input.criteria : [];
    if (raw.length > MAX_PARTS) throw fail(`A rubric can have at most ${MAX_PARTS} parts`);
    const criteria = raw.map((part) => {
        const label = String(part?.label ?? '').trim();
        const maxPoints = Number(part?.maxPoints);
        if (!label || label.length > 80) throw fail('Each part needs a name of up to 80 characters');
        if (!Number.isInteger(maxPoints) || maxPoints < 1 || maxPoints > 1000) throw fail(`"${label}" must be out of a whole number between 1 and 1000`);
        return { label, maxPoints };
    });
    if (enabled && criteria.length === 0) throw fail('Add at least one part to mark by parts');
    if (enabled && rubricTotal({ criteria }) > 1000) throw fail('The parts can add up to at most 1000 points');
    return { enabled, criteria };
};

const rubricTotal = (rubric) => (rubric?.criteria || []).reduce((sum, c) => sum + Number(c.maxPoints || 0), 0);

const isRubricOn = (assignment) => Boolean(assignment?.rubric?.enabled && assignment.rubric.criteria?.length);

// A teacher's scores for each part, in the rubric's order: numbers or
// { points }. -> { grade, rubricScores } with a copy of each part's name, so
// later edits to the rubric don't change marks already given.
const scoreFromRubric = (rubric, scores) => {
    const criteria = rubric?.criteria || [];
    if (!Array.isArray(scores) || scores.length !== criteria.length) throw fail('Score every part of the rubric');
    const rubricScores = criteria.map((part, i) => {
        const raw = scores[i] !== null && typeof scores[i] === 'object' ? scores[i].points : scores[i];
        const points = Number(raw);
        if (raw === '' || raw === null || raw === undefined || !Number.isFinite(points) || points < 0 || points > part.maxPoints) {
            throw fail(`"${part.label}" must be between 0 and ${part.maxPoints}`);
        }
        return { label: part.label, maxPoints: part.maxPoints, points };
    });
    return { grade: rubricScores.reduce((sum, s) => sum + s.points, 0), rubricScores };
};

// What a marking request sets on a submission, for either way of marking.
// body: { grade } or { rubricScores }. -> { grade, rubricScores } or null
// when the request gives no mark (only feedback or a status).
const markFromRequest = (assignment, body = {}) => {
    const hasGrade = body.grade !== undefined && body.grade !== null && body.grade !== '';
    if (isRubricOn(assignment)) {
        if (body.rubricScores === undefined) {
            if (hasGrade) throw fail('This assignment is marked part by part. Score each part.');
            return null;
        }
        return scoreFromRubric(assignment.rubric, body.rubricScores);
    }
    if (!hasGrade) return null;
    const grade = Number(body.grade);
    if (!Number.isFinite(grade) || grade < 0 || grade > assignment.maxPoints) {
        throw fail(`grade must be between 0 and ${assignment.maxPoints}`);
    }
    return { grade, rubricScores: [] };
};

module.exports = { normalizeRubric, rubricTotal, isRubricOn, scoreFromRubric, markFromRequest, MAX_PARTS };
