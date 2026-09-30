const express = require('express');
const mongoose = require('mongoose');
const VideoQuestion = require('../models/videoQuestions');
const VideoQuizAttempt = require('../models/videoQuizAttempt');
const Video = require('../models/videos');
const { authenticateAdmin, optionalToken } = require('../middlewares/auth');

const router = express.Router();

const readOptions = (value) => {
    if (Array.isArray(value)) return value.map((v) => String(v).trim()).filter(Boolean);
    if (typeof value === 'string') {
        try {
            const parsed = JSON.parse(value);
            if (Array.isArray(parsed)) return parsed.map((v) => String(v).trim()).filter(Boolean);
        } catch (e) {
            // fall through to splitting
        }
        return value.split(/\r?\n|,/).map((v) => v.trim().replace(/^"(.*)"$/, '$1')).filter(Boolean);
    }
    return [];
};

const answerIndex = (question) => {
    const options = readOptions(question.options_en);
    const wanted = String(question.correct_answer ?? '').trim().toLowerCase();
    const found = options.findIndex((o) => o.toLowerCase() === wanted);
    if (found >= 0) return found;
    const numeric = Number.parseInt(question.correct_answer, 10);
    return Number.isInteger(numeric) && numeric >= 0 && numeric < options.length ? numeric : 0;
};

// Public practice settings are separate from the question payload so older
// clients can continue consuming the bare question array.
router.get('/settings', optionalToken, async (req, res) => {
    try {
        const { videoId } = req.query;
        if (!videoId || !mongoose.Types.ObjectId.isValid(videoId)) {
            return res.status(400).json({ message: 'A valid videoId is required' });
        }
        const video = await Video.findById(videoId).select('practiceEnabled practiceTimerMode practiceOverallTimeLimit practicePerQuestionTimeLimit practiceStartDate practiceEndDate practiceConditions');
        if (!video) return res.status(404).json({ message: 'Video not found' });
        const now = new Date();
        const inWindow = (!video.practiceStartDate || now >= video.practiceStartDate) && (!video.practiceEndDate || now <= video.practiceEndDate);
        res.json({
            enabled: video.practiceEnabled !== false,
            available: video.practiceEnabled !== false && inWindow,
            timerMode: video.practiceTimerMode || 'none',
            overallTimeLimit: video.practiceOverallTimeLimit,
            perQuestionTimeLimit: video.practicePerQuestionTimeLimit,
            startDate: video.practiceStartDate,
            endDate: video.practiceEndDate,
            conditions: video.practiceConditions || {}
        });
    } catch (error) {
        console.error('Error fetching video practice settings:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// videoId is required on create, optional on update (PUT keeps the existing
// video link when omitted).
const buildPayload = (body, { requireVideoId }) => {
    const required = ['question_en', 'question_ml', 'options_en', 'options_ml', 'correct_answer'];
    if (requireVideoId) required.unshift('videoId');

    for (const field of required) {
        const value = body[field];
        if (value === undefined || value === null || String(value).trim() === '') {
            return { error: `${field} is required` };
        }
    }
    if (body.videoId !== undefined && body.videoId !== '' && !mongoose.Types.ObjectId.isValid(body.videoId)) {
        return { error: 'videoId must be a valid id' };
    }

    const data = {
        type: body.type || 'Multiple Choice',
        question_en: String(body.question_en).trim(),
        question_ml: String(body.question_ml).trim(),
        options_en: Array.isArray(body.options_en) ? JSON.stringify(body.options_en) : String(body.options_en).trim(),
        options_ml: Array.isArray(body.options_ml) ? JSON.stringify(body.options_ml) : String(body.options_ml).trim(),
        correct_answer: String(body.correct_answer).trim(),
        difficulty: body.difficulty || 'Easy',
        order: Number(body.order) || 0
    };
    if (body.videoId) data.videoId = body.videoId;

    return { data };
};

// GET /api/video-questions?videoId=<id>
// public: bare array without correct_answer; admin: { items, total } with correct_answer.
router.get('/', optionalToken, async (req, res) => {
    try {
        const { videoId } = req.query;
        if (!videoId || !mongoose.Types.ObjectId.isValid(videoId)) {
            return res.status(400).json({ message: 'A valid videoId is required' });
        }

        const questions = await VideoQuestion.find({ videoId }).sort({ order: 1, createdAt: 1 }).lean();

        if (req.isAdmin) {
            return res.json({ items: questions, total: questions.length });
        }

        return res.json(
            questions.map((question) => {
                const { correct_answer, ...rest } = question;
                return {
                    ...rest,
                    options_en: readOptions(question.options_en),
                    options_ml: readOptions(question.options_ml)
                };
            })
        );
    } catch (error) {
        console.error('Error fetching video questions:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
});

// Video ids that currently have questions, so the admin can show a badge.
router.get('/counts', authenticateAdmin, async (req, res) => {
    try {
        const rows = await VideoQuestion.aggregate([
            { $group: { _id: '$videoId', count: { $sum: 1 } } }
        ]);
        return res.json(rows.map((row) => ({ videoId: row._id, count: row.count })));
    } catch (error) {
        console.error('Error counting video questions:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
});

router.post('/', authenticateAdmin, async (req, res) => {
    try {
        const { data, error } = buildPayload(req.body || {}, { requireVideoId: true });
        if (error) return res.status(400).json({ message: error });

        const video = await Video.findById(data.videoId).select('_id');
        if (!video) return res.status(404).json({ message: 'Video not found' });

        const created = await VideoQuestion.create(data);
        return res.status(201).json(created);
    } catch (error) {
        console.error('Error creating video question:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
});

router.put('/:id', authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid question id' });
        }
        const { data, error } = buildPayload(req.body || {}, { requireVideoId: false });
        if (error) return res.status(400).json({ message: error });

        if (data.videoId) {
            const video = await Video.findById(data.videoId).select('_id');
            if (!video) return res.status(404).json({ message: 'Video not found' });
        }

        const updated = await VideoQuestion.findByIdAndUpdate(id, data, { new: true, runValidators: true });
        if (!updated) return res.status(404).json({ message: 'Question not found' });
        return res.json(updated);
    } catch (error) {
        console.error('Error updating video question:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/video-questions/:id - also pulls the question from any
// videoQuizAttempt.answers and recomputes score/percentage/totalQuestions so
// deleting a question never leaves a stale attempt pointing at nothing.
router.delete('/:id', authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid question id' });
        }
        const deleted = await VideoQuestion.findByIdAndDelete(id);
        if (!deleted) return res.status(404).json({ message: 'Question not found' });

        const affected = await VideoQuizAttempt.find({ 'answers.questionId': id });
        for (const attempt of affected) {
            attempt.answers = attempt.answers.filter((a) => String(a.questionId) !== String(id));
            attempt.totalQuestions = attempt.answers.length;
            attempt.score = attempt.answers.filter((a) => a.isCorrect).length;
            attempt.percentage = attempt.totalQuestions > 0
                ? Math.round((attempt.score / attempt.totalQuestions) * 100)
                : 0;
            await attempt.save();
        }

        return res.json({ message: 'Question deleted' });
    } catch (error) {
        console.error('Error deleting video question:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
