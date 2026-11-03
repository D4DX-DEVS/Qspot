const express = require('express');
const mongoose = require('mongoose');
const User = require('../models/user');
const Subject = require('../models/subject');
const Video = require('../models/videos');
const VideoProgress = require('../models/videoProgress');
const VideoQuizAttempt = require('../models/videoQuizAttempt');
const Quiz = require('../models/quiz');
const QuizConfig = require('../models/quizConfig');
const Assignment = require('../models/assignment');
const AssignmentSubmission = require('../models/assignmentSubmission');
const { authenticateAdmin } = require('../middlewares/auth');
const { buildGradebook } = require('../services/gradebook');
const { isUpcoming } = require('../services/progressSummary');

// Admin gradebook and marking queue. Mounted at /api/admin/gradebook.
const router = express.Router();

const LEARNER_LIMIT = 300;
const QUEUE_LIMIT = 100;

// Accounts saved before roles existed have no role and are learners.
const learnerFilter = (cls) => ({
    $or: [{ role: 'student' }, { role: { $exists: false } }],
    ...(cls ? { class: cls } : {})
});

const readFilters = (query) => ({
    cls: String(query.class || '').trim().slice(0, 80),
    courseId: mongoose.Types.ObjectId.isValid(query.courseId) ? String(query.courseId) : null
});

// Published assignments for the class (or every class) and course.
const assignmentFilter = ({ cls, courseId }, now, { releasedOnly }) => {
    const and = [];
    if (releasedOnly) and.push({ $or: [{ releaseAt: null }, { releaseAt: { $lte: now } }] });
    if (cls) and.push({ $or: [{ class: '' }, { class: null }, { class: cls }] });
    return { isPublished: true, ...(courseId ? { courseId } : {}), ...(and.length ? { $and: and } : {}) };
};

// GET /api/admin/gradebook/classes - every learner class, for the filter.
router.get('/classes', authenticateAdmin, async (req, res) => {
    try {
        const classes = await User.distinct('class', learnerFilter(''));
        res.json(classes.filter((c) => typeof c === 'string' && c.trim()).sort((a, b) => a.localeCompare(b, undefined, { numeric: true })));
    } catch (error) {
        console.error('Error fetching gradebook classes:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/admin/gradebook?class=7&courseId=<id>
// Exams are linked to learners by class only, so the course filter applies to
// assignments, practice and lessons.
router.get('/', authenticateAdmin, async (req, res) => {
    try {
        const filters = readFilters(req.query);
        const now = new Date();

        const learnerRows = await User.find(learnerFilter(filters.cls)).select('name class').sort({ name: 1 }).limit(LEARNER_LIMIT + 1).lean();
        const truncated = learnerRows.length > LEARNER_LIMIT;
        const learners = learnerRows.slice(0, LEARNER_LIMIT);
        const userIds = learners.map((l) => l._id);

        const examFilter = { isEnable: true, startDate: { $lte: now } };
        if (filters.cls) {
            examFilter.$or = [{ allowedClasses: { $exists: false } }, { allowedClasses: { $size: 0 } }, { allowedClasses: filters.cls }];
        }
        const subjectIds = filters.courseId
            ? (await Subject.find({ courseId: filters.courseId }).select('_id').lean()).map((s) => s._id)
            : null;
        const [exams, assignments, videos] = await Promise.all([
            QuizConfig.find(examFilter).select('title startDate endDate').sort({ startDate: 1 }).lean(),
            Assignment.find(assignmentFilter(filters, now, { releasedOnly: true })).select('title maxPoints dueAt').sort({ dueAt: 1, createdAt: 1 }).lean(),
            Video.find({ isPublished: { $ne: false }, ...(subjectIds ? { subject: { $in: subjectIds } } : {}) }).select('_id releaseDate').lean()
        ]);
        const lessonIds = videos.filter((v) => !isUpcoming(v.releaseDate, now)).map((v) => v._id);

        const [attempts, submissions, practice, lessons] = await Promise.all([
            Quiz.find({ userId: { $in: userIds }, quizId: { $in: exams.map((e) => e._id) } }).select('userId quizId percentage').lean(),
            AssignmentSubmission.find({ userId: { $in: userIds }, assignmentId: { $in: assignments.map((a) => a._id) } })
                .select('userId assignmentId status grade submittedAt').lean(),
            VideoQuizAttempt.aggregate([
                { $match: { userId: { $in: userIds }, videoId: { $in: lessonIds } } },
                { $group: { _id: '$userId', avg: { $avg: '$percentage' } } }
            ]),
            VideoProgress.aggregate([
                { $match: { userId: { $in: userIds }, videoId: { $in: lessonIds }, completed: true } },
                { $group: { _id: '$userId', count: { $sum: 1 } } }
            ])
        ]);

        res.json({
            ...buildGradebook({
                learners,
                exams,
                assignments,
                attempts,
                submissions,
                practiceByUser: new Map(practice.map((p) => [String(p._id), p.avg])),
                lessonsByUser: new Map(lessons.map((l) => [String(l._id), l.count])),
                lessonsTotal: lessonIds.length,
                now
            }),
            truncated,
            learnerLimit: LEARNER_LIMIT
        });
    } catch (error) {
        console.error('Error building gradebook:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

const shapeSubmission = (submission, assignment) => ({
    id: String(submission._id),
    assignmentId: String(submission.assignmentId?._id || submission.assignmentId),
    assignment: assignment
        ? {
            id: String(assignment._id),
            title: assignment.title,
            maxPoints: assignment.maxPoints,
            dueAt: assignment.dueAt || null,
            rubric: assignment.rubric?.enabled ? assignment.rubric : { enabled: false, criteria: [] }
        }
        : null,
    learner: submission.userId && submission.userId._id
        ? { id: String(submission.userId._id), name: submission.userId.name || '', class: submission.userId.class || '' }
        : null,
    text: submission.text || '',
    files: submission.files || [],
    status: submission.status,
    late: Boolean(assignment?.dueAt) && new Date(submission.submittedAt) > new Date(assignment.dueAt),
    grade: submission.grade ?? null,
    rubricScores: submission.rubricScores || [],
    feedback: submission.feedback || '',
    submittedAt: submission.submittedAt
});

// GET /api/admin/gradebook/queue?class=7&courseId=<id>
// Work waiting for a mark, oldest first.
router.get('/queue', authenticateAdmin, async (req, res) => {
    try {
        const filters = readFilters(req.query);
        const assignments = await Assignment.find(assignmentFilter(filters, new Date(), { releasedOnly: false })).select('title maxPoints dueAt rubric').lean();
        const byId = new Map(assignments.map((a) => [String(a._id), a]));
        const submissionFilter = { assignmentId: { $in: assignments.map((a) => a._id) }, status: { $in: ['submitted', 'late'] } };
        if (filters.cls) {
            const ids = await User.find(learnerFilter(filters.cls)).distinct('_id');
            submissionFilter.userId = { $in: ids };
        }
        const [items, total] = await Promise.all([
            AssignmentSubmission.find(submissionFilter).sort({ submittedAt: 1 }).limit(QUEUE_LIMIT).populate('userId', 'name class').lean(),
            AssignmentSubmission.countDocuments(submissionFilter)
        ]);
        res.json({ items: items.map((s) => shapeSubmission(s, byId.get(String(s.assignmentId)))), total });
    } catch (error) {
        console.error('Error fetching marking queue:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/admin/gradebook/submissions/:id - one submission for the side panel.
// Marks are saved with PUT /api/admin/assignments/:id/submissions/:submissionId.
router.get('/submissions/:id', authenticateAdmin, async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) return res.status(400).json({ message: 'Invalid submission id' });
        const submission = await AssignmentSubmission.findById(req.params.id).populate('userId', 'name class').lean();
        if (!submission) return res.status(404).json({ message: 'Submission not found' });
        const assignment = await Assignment.findById(submission.assignmentId).select('title maxPoints dueAt rubric').lean();
        res.json(shapeSubmission(submission, assignment));
    } catch (error) {
        console.error('Error fetching submission:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
