const express = require('express');
const mongoose = require('mongoose');
const Assignment = require('../models/assignment');
const AssignmentSubmission = require('../models/assignmentSubmission');
const Course = require('../models/course');
const Subject = require('../models/subject');
const Video = require('../models/videos');
const { authenticateAdmin, authenticateUser } = require('../middlewares/auth');
const { recordLearningEvent } = require('../services/learningEvents');
const { assignmentUpload, getCdnUrl } = require('../services/cdnStorageService');

const userRouter = express.Router();
const adminRouter = express.Router();

const validId = (value) => mongoose.Types.ObjectId.isValid(value);
const escapeRegExp = (value) => String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const asDate = (value, field) => {
    if (value === undefined || value === null || value === '') return null;
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
        const error = new Error(`${field} must be a valid date`);
        error.status = 400;
        throw error;
    }
    return date;
};

const ensureRefs = async ({ courseId, subjectId, videoId }) => {
    if (courseId !== undefined && courseId !== null && courseId !== '' && !validId(courseId)) {
        return 'Invalid courseId';
    }
    if (subjectId !== undefined && subjectId !== null && subjectId !== '' && !validId(subjectId)) {
        return 'Invalid subjectId';
    }
    if (videoId !== undefined && videoId !== null && videoId !== '' && !validId(videoId)) {
        return 'Invalid videoId';
    }

    const [course, subject, video] = await Promise.all([
        courseId ? Course.findById(courseId).select('_id') : null,
        subjectId ? Subject.findById(subjectId).select('_id courseId') : null,
        videoId ? Video.findById(videoId).select('_id subject') : null
    ]);
    if (courseId && !course) return 'Course not found';
    if (subjectId && !subject) return 'Subject not found';
    if (videoId && !video) return 'Video not found';
    if (course && subject && subject.courseId && String(subject.courseId) !== String(course._id)) {
        return 'subjectId does not belong to courseId';
    }
    if (video && subjectId && String(video.subject) !== String(subjectId)) {
        return 'videoId does not belong to subjectId';
    }
    return null;
};

const validateFiles = (files, assignment) => {
    if (files === undefined) return [];
    if (!Array.isArray(files) || files.length > 10) throw Object.assign(new Error('files must be an array of at most 10 items'), { status: 400 });
    return files.map((file) => {
        if (!file || typeof file !== 'object' || !String(file.name || '').trim() || !String(file.url || '').trim()) {
            throw Object.assign(new Error('Each file requires name and url'), { status: 400 });
        }
        const name = String(file.name).trim();
        const url = String(file.url).trim();
        const mimeType = String(file.mimeType || 'application/octet-stream').trim();
        const size = Number(file.size || 0);
        if (name.length > 255 || url.length > 2000 || mimeType.length > 120 || !Number.isFinite(size) || size < 0) {
            throw Object.assign(new Error('Invalid file metadata'), { status: 400 });
        }
        if (!/^https?:\/\//i.test(url) && !url.startsWith('/')) {
            throw Object.assign(new Error('file url must be an http(s) URL or an app-relative path'), { status: 400 });
        }
        if (assignment.allowedMimeTypes.length && !assignment.allowedMimeTypes.includes(mimeType)) {
            throw Object.assign(new Error(`File type ${mimeType} is not allowed for this assignment`), { status: 400 });
        }
        if (size > assignment.maxFileSizeBytes) {
            throw Object.assign(new Error(`File ${name} exceeds the assignment size limit`), { status: 400 });
        }
        return { name, url, key: file.key ? String(file.key).slice(0, 500) : null, mimeType, size };
    });
};

const validateMetadata = (metadata) => {
    if (metadata === undefined || metadata === null) return {};
    if (typeof metadata !== 'object' || Array.isArray(metadata)) {
        throw Object.assign(new Error('metadata must be an object'), { status: 400 });
    }
    if (JSON.stringify(metadata).length > 20000) {
        throw Object.assign(new Error('metadata is too large'), { status: 400 });
    }
    return metadata;
};

const normalizeAssignmentInput = (body, existing = null) => {
    const value = (key, fallback) => body[key] === undefined ? fallback : body[key];
    const title = value('title', existing?.title || '');
    if (typeof title !== 'string' || !title.trim() || title.trim().length > 200) throw Object.assign(new Error('title is required and must be at most 200 characters'), { status: 400 });
    const releaseAt = asDate(value('releaseAt', existing?.releaseAt || null), 'releaseAt');
    const dueAt = asDate(value('dueAt', existing?.dueAt || null), 'dueAt');
    if (releaseAt && dueAt && dueAt < releaseAt) throw Object.assign(new Error('dueAt must be after releaseAt'), { status: 400 });
    const maxPoints = Number(value('maxPoints', existing?.maxPoints ?? 100));
    if (!Number.isInteger(maxPoints) || maxPoints < 1 || maxPoints > 1000) throw Object.assign(new Error('maxPoints must be an integer between 1 and 1000'), { status: 400 });
    const maxFileSizeBytes = Number(value('maxFileSizeBytes', existing?.maxFileSizeBytes ?? 10 * 1024 * 1024));
    if (!Number.isInteger(maxFileSizeBytes) || maxFileSizeBytes < 1 || maxFileSizeBytes > 100 * 1024 * 1024) throw Object.assign(new Error('maxFileSizeBytes is invalid'), { status: 400 });
    const allowedMimeTypes = value('allowedMimeTypes', existing?.allowedMimeTypes || []);
    if (!Array.isArray(allowedMimeTypes) || allowedMimeTypes.length > 20 || allowedMimeTypes.some((mime) => typeof mime !== 'string' || mime.trim().length > 120)) throw Object.assign(new Error('allowedMimeTypes must be an array of at most 20 strings'), { status: 400 });

    return {
        title: title.trim(),
        instructions: String(value('instructions', existing?.instructions || '')).slice(0, 10000),
        courseId: value('courseId', existing?.courseId || null) || null,
        subjectId: value('subjectId', existing?.subjectId || null) || null,
        videoId: value('videoId', existing?.videoId || null) || null,
        class: String(value('class', existing?.class || '') || '').trim().slice(0, 80),
        releaseAt,
        dueAt,
        maxPoints,
        allowedMimeTypes: allowedMimeTypes.map((mime) => mime.trim()).filter(Boolean),
        maxFileSizeBytes,
        isPublished: value('isPublished', existing?.isPublished ?? false) === true || String(value('isPublished', existing?.isPublished ?? false)) === 'true'
    };
};

const assignmentForLearner = async (id, user) => {
    if (!validId(id)) return null;
    const now = new Date();
    const assignment = await Assignment.findOne({
        _id: id,
        isPublished: true,
        $or: [{ releaseAt: null }, { releaseAt: { $lte: now } }],
        $and: [{ $or: [{ class: '' }, { class: null }, { class: user.class }] }]
    }).populate('courseId', 'title').populate('subjectId', 'name').populate('videoId', 'title');
    return assignment;
};

const shapeLearnerAssignment = (assignment, submission = null) => {
    const value = assignment.toObject ? assignment.toObject() : assignment;
    const now = new Date();
    const due = value.dueAt ? new Date(value.dueAt) : null;
    let status = submission?.status || 'not-started';
    if (submission && due && new Date(submission.submittedAt) > due && status === 'submitted') status = 'late';
    if (!submission && due && due < now) status = 'overdue';
    return {
        ...value,
        id: String(value._id),
        status,
        submission: submission ? {
            id: String(submission._id),
            text: submission.text,
            files: submission.files,
            metadata: submission.metadata,
            status: submission.status,
            grade: submission.grade,
            feedback: submission.feedback,
            submittedAt: submission.submittedAt,
            gradedAt: submission.gradedAt
        } : null
    };
};

const uploadAssignmentFiles = (req, res, next) => {
    assignmentUpload.array('files', 10)(req, res, (error) => {
        if (error) {
            if (error.code === 'LIMIT_FILE_SIZE') error.status = 413;
            else if (!error.status) error.status = 400;
            return next(error);
        }
        if (Array.isArray(req.files) && req.files.length > 0) {
            req.body.files = req.files.map((file) => ({
                name: file.originalname,
                url: file.location || (file.key ? getCdnUrl(file.key) : `/uploads/assignments/${file.filename}`),
                key: file.key || null,
                mimeType: file.mimetype,
                size: file.size || 0
            }));
        }
        if (typeof req.body.metadata === 'string') {
            try {
                req.body.metadata = JSON.parse(req.body.metadata);
            } catch (_) {
                return res.status(400).json({ message: 'metadata must be valid JSON' });
            }
        }
        next();
    });
};

// Learner-facing routes. Every read is constrained to the authenticated learner's class.
userRouter.get('/', authenticateUser, async (req, res) => {
    try {
        const now = new Date();
        const assignments = await Assignment.find({
            isPublished: true,
            $or: [{ releaseAt: null }, { releaseAt: { $lte: now } }],
            $and: [{ $or: [{ class: '' }, { class: null }, { class: req.user.class }] }]
        }).sort({ dueAt: 1, releaseAt: -1, createdAt: -1 }).populate('courseId', 'title').populate('subjectId', 'name').populate('videoId', 'title').lean();
        const submissions = await AssignmentSubmission.find({ assignmentId: { $in: assignments.map((a) => a._id) }, userId: req.user.id }).lean();
        const submissionMap = new Map(submissions.map((submission) => [String(submission.assignmentId), submission]));
        res.json(assignments.map((assignment) => shapeLearnerAssignment(assignment, submissionMap.get(String(assignment._id)) || null)));
    } catch (error) {
        console.error('Error fetching learner assignments:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

userRouter.get('/:id', authenticateUser, async (req, res) => {
    try {
        const assignment = await assignmentForLearner(req.params.id, req.user);
        if (!assignment) return res.status(404).json({ message: 'Assignment not found' });
        const submission = await AssignmentSubmission.findOne({ assignmentId: assignment._id, userId: req.user.id }).lean();
        res.json(shapeLearnerAssignment(assignment, submission));
    } catch (error) {
        console.error('Error fetching learner assignment:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

const submitAssignment = async (req, res) => {
    try {
        const assignment = await assignmentForLearner(req.params.id, req.user);
        if (!assignment) return res.status(404).json({ message: 'Assignment not found' });
        const body = req.body || {};
        const text = body.text === undefined || body.text === null ? '' : String(body.text);
        if (text.length > 20000) return res.status(400).json({ message: 'text must be at most 20000 characters' });
        const files = validateFiles(body.files, assignment);
        const metadata = validateMetadata(body.metadata);
        if (!text.trim() && !files.length) return res.status(400).json({ message: 'Provide text or at least one file' });

        const now = new Date();
        const late = assignment.dueAt && now > new Date(assignment.dueAt);
        const submission = await AssignmentSubmission.findOneAndUpdate(
            { assignmentId: assignment._id, userId: req.user.id },
            { $set: { text, files, metadata, status: late ? 'late' : 'submitted', submittedAt: now, grade: null, feedback: '', gradedAt: null, gradedBy: '' }, $setOnInsert: { assignmentId: assignment._id, userId: req.user.id } },
            { upsert: true, new: true, runValidators: true }
        );
        await recordLearningEvent({ userId: req.user.id, type: 'assignment_submitted', sourceType: 'assignment', sourceId: assignment._id, occurredAt: now });
        res.status(201).json({ message: 'Assignment submitted successfully', submission: shapeLearnerAssignment(assignment, submission).submission });
    } catch (error) {
        console.error('Error submitting assignment:', error);
        res.status(error.status || 500).json({ message: error.status ? error.message : 'Internal server error' });
    }
};

userRouter.post('/:id/submit', authenticateUser, uploadAssignmentFiles, submitAssignment);
userRouter.post('/:id/submissions', authenticateUser, uploadAssignmentFiles, submitAssignment);

// Admin CRUD and teacher-facing submission review. Admin auth is deliberately used
// here because the current panel has no faculty-scoped JWT contract yet.
adminRouter.get('/', authenticateAdmin, async (req, res) => {
    try {
        const page = Math.max(1, parseInt(req.query.page, 10) || 1);
        const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));
        const filter = {};
        if (req.query.search) filter.title = new RegExp(escapeRegExp(String(req.query.search).trim()), 'i');
        if (req.query.class) filter.class = String(req.query.class).trim();
        if (req.query.isPublished !== undefined) filter.isPublished = String(req.query.isPublished) === 'true';
        const [items, total] = await Promise.all([
            Assignment.find(filter).sort({ dueAt: 1, createdAt: -1 }).skip((page - 1) * limit).limit(limit).populate('courseId', 'title').populate('subjectId', 'name').populate('videoId', 'title').lean(),
            Assignment.countDocuments(filter)
        ]);
        const counts = await AssignmentSubmission.aggregate([{ $match: { assignmentId: { $in: items.map((item) => item._id) } } }, { $group: { _id: '$assignmentId', count: { $sum: 1 } } }]);
        const countMap = new Map(counts.map((item) => [String(item._id), item.count]));
        res.json({ items: items.map((item) => ({ ...item, id: String(item._id), submissionCount: countMap.get(String(item._id)) || 0 })), total, page, limit });
    } catch (error) {
        console.error('Error fetching admin assignments:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

adminRouter.get('/:id', authenticateAdmin, async (req, res) => {
    try {
        if (!validId(req.params.id)) return res.status(400).json({ message: 'Invalid assignment id' });
        const assignment = await Assignment.findById(req.params.id).populate('courseId', 'title').populate('subjectId', 'name').populate('videoId', 'title');
        if (!assignment) return res.status(404).json({ message: 'Assignment not found' });
        const submissionCount = await AssignmentSubmission.countDocuments({ assignmentId: assignment._id });
        res.json({ assignment, submissionCount });
    } catch (error) {
        console.error('Error fetching admin assignment:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

adminRouter.post('/', authenticateAdmin, async (req, res) => {
    try {
        const data = normalizeAssignmentInput(req.body || {});
        const refError = await ensureRefs(data);
        if (refError) return res.status(400).json({ message: refError });
        const assignment = await Assignment.create({ ...data, createdBy: req.user.username || '' });
        res.status(201).json({ message: 'Assignment created successfully', assignment });
    } catch (error) {
        console.error('Error creating assignment:', error);
        res.status(error.status || 500).json({ message: error.status ? error.message : 'Internal server error' });
    }
});

adminRouter.put('/:id', authenticateAdmin, async (req, res) => {
    try {
        if (!validId(req.params.id)) return res.status(400).json({ message: 'Invalid assignment id' });
        const existing = await Assignment.findById(req.params.id);
        if (!existing) return res.status(404).json({ message: 'Assignment not found' });
        const data = normalizeAssignmentInput(req.body || {}, existing);
        const refError = await ensureRefs(data);
        if (refError) return res.status(400).json({ message: refError });
        const assignment = await Assignment.findByIdAndUpdate(existing._id, data, { new: true, runValidators: true });
        res.json({ message: 'Assignment updated successfully', assignment });
    } catch (error) {
        console.error('Error updating assignment:', error);
        res.status(error.status || 500).json({ message: error.status ? error.message : 'Internal server error' });
    }
});

adminRouter.delete('/:id', authenticateAdmin, async (req, res) => {
    try {
        if (!validId(req.params.id)) return res.status(400).json({ message: 'Invalid assignment id' });
        const assignment = await Assignment.findByIdAndDelete(req.params.id);
        if (!assignment) return res.status(404).json({ message: 'Assignment not found' });
        await AssignmentSubmission.deleteMany({ assignmentId: assignment._id });
        res.json({ message: 'Assignment deleted successfully', id: assignment._id });
    } catch (error) {
        console.error('Error deleting assignment:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

adminRouter.get('/:id/submissions', authenticateAdmin, async (req, res) => {
    try {
        if (!validId(req.params.id)) return res.status(400).json({ message: 'Invalid assignment id' });
        if (!await Assignment.exists({ _id: req.params.id })) return res.status(404).json({ message: 'Assignment not found' });
        const page = Math.max(1, parseInt(req.query.page, 10) || 1);
        const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 50));
        const filter = { assignmentId: req.params.id };
        if (['submitted', 'late', 'graded', 'returned'].includes(req.query.status)) filter.status = req.query.status;
        const [items, total] = await Promise.all([
            AssignmentSubmission.find(filter).sort({ submittedAt: -1 }).skip((page - 1) * limit).limit(limit).populate('userId', 'name phone email class'),
            AssignmentSubmission.countDocuments(filter)
        ]);
        res.json({ items, total, page, limit });
    } catch (error) {
        console.error('Error fetching assignment submissions:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

adminRouter.put('/:id/submissions/:submissionId', authenticateAdmin, async (req, res) => {
    try {
        const { id, submissionId } = req.params;
        if (!validId(id) || !validId(submissionId)) return res.status(400).json({ message: 'Invalid assignment or submission id' });
        const assignment = await Assignment.findById(id).select('maxPoints');
        if (!assignment) return res.status(404).json({ message: 'Assignment not found' });
        const submission = await AssignmentSubmission.findOne({ _id: submissionId, assignmentId: id });
        if (!submission) return res.status(404).json({ message: 'Submission not found' });
        const body = req.body || {};
        const update = {};
        if (body.feedback !== undefined) {
            if (typeof body.feedback !== 'string' || body.feedback.length > 10000) return res.status(400).json({ message: 'feedback is invalid' });
            update.feedback = body.feedback;
        }
        if (body.grade !== undefined && body.grade !== null && body.grade !== '') {
            const grade = Number(body.grade);
            if (!Number.isFinite(grade) || grade < 0 || grade > assignment.maxPoints) return res.status(400).json({ message: `grade must be between 0 and ${assignment.maxPoints}` });
            update.grade = grade;
            update.status = 'graded';
        }
        if (body.status !== undefined) {
            if (!['submitted', 'late', 'graded', 'returned'].includes(body.status)) return res.status(400).json({ message: 'Invalid submission status' });
            update.status = body.status;
        }
        if (!Object.keys(update).length) return res.status(400).json({ message: 'Provide grade, feedback, or status' });
        if (update.status === 'graded' || update.grade !== undefined) {
            update.gradedAt = new Date();
            update.gradedBy = req.user.username || '';
        }
        const updated = await AssignmentSubmission.findByIdAndUpdate(submission._id, update, { new: true, runValidators: true }).populate('userId', 'name phone email class');
        res.json({ message: 'Submission updated successfully', submission: updated });
    } catch (error) {
        console.error('Error updating assignment submission:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = { userRouter, adminRouter };
