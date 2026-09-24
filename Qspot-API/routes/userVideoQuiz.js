const express = require('express');
const mongoose = require('mongoose');
const VideoQuestion = require('../models/videoQuestions');
const VideoQuizAttempt = require('../models/videoQuizAttempt');
const VideoProgress = require('../models/videoProgress');
const Video = require('../models/videos');
const { authenticateUser } = require('../middlewares/auth');
const { recordLearningEvent } = require('../services/learningEvents');

const router = express.Router();

const readOptions = (value) => {
    if (Array.isArray(value)) return value.map((v) => String(v).trim()).filter(Boolean);
    if (typeof value === 'string') {
        try {
            const parsed = JSON.parse(value);
            if (Array.isArray(parsed)) return parsed.map((v) => String(v).trim()).filter(Boolean);
        } catch (e) {
            // fall through
        }
        return value.split(/\r?\n|,/).map((v) => v.trim()).filter(Boolean);
    }
    return [];
};

const correctIndex = (question, optionsEn) => {
    const expected = String(question.correct_answer ?? '').trim().toLowerCase();
    const found = optionsEn.findIndex((o) => o.toLowerCase() === expected);
    if (found >= 0) return found;
    const numeric = Number.parseInt(question.correct_answer, 10);
    return Number.isInteger(numeric) && numeric >= 0 && numeric < optionsEn.length ? numeric : -1;
};

const buildResult = async (attempt) => {
    const questions = await VideoQuestion.find({ _id: { $in: attempt.answers.map((a) => a.questionId) } });
    const byId = new Map(questions.map((q) => [String(q._id), q]));

    const results = attempt.answers.map((ans) => {
        const q = byId.get(String(ans.questionId));
        const optionsEn = readOptions(q?.options_en);
        const optionsMl = readOptions(q?.options_ml);
        return {
            questionId: ans.questionId,
            type: q?.type || 'Multiple Choice',
            question_en: q?.question_en || '',
            question_ml: q?.question_ml || '',
            options_en: optionsEn,
            options_ml: optionsMl,
            attemptedAnswer: ans.attemptedAnswer !== null && ans.attemptedAnswer !== undefined
                ? Number.parseInt(ans.attemptedAnswer, 10)
                : null,
            correctAnswer: q ? correctIndex(q, optionsEn) : -1,
            isCorrect: Boolean(ans.isCorrect)
        };
    });

    return {
        attemptId: attempt._id,
        videoId: attempt.videoId,
        language: attempt.language,
        score: attempt.score,
        totalQuestions: attempt.totalQuestions,
        percentage: attempt.percentage,
        createdAt: attempt.createdAt,
        results
    };
};

// GET /api/user/video-quiz?videoId=<id> - this user's result for that video
router.get('/', authenticateUser, async (req, res) => {
    try {
        const { videoId } = req.query;
        if (!videoId || !mongoose.Types.ObjectId.isValid(videoId)) {
            return res.status(400).json({ message: 'A valid videoId is required' });
        }
        const attempt = await VideoQuizAttempt.findOne({ userId: req.user.id, videoId });
        if (!attempt) return res.json(null);
        return res.json(await buildResult(attempt));
    } catch (error) {
        console.error('Error fetching video quiz attempt:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/user/video-quiz - submit answers for the questions on one video.
// body: { videoId, language, answers: [{ questionId, attemptedAnswer }] }
router.post('/', authenticateUser, async (req, res) => {
    try {
        const { videoId, language, answers } = req.body || {};

        if (!videoId || !mongoose.Types.ObjectId.isValid(videoId)) {
            return res.status(400).json({ message: 'Invalid videoId' });
        }
        if (!Array.isArray(answers) || answers.length === 0) {
            return res.status(400).json({ message: 'answers must be a non-empty array' });
        }

        const video = await Video.findById(videoId).select('practiceEnabled practiceStartDate practiceEndDate');
        if (!video) return res.status(404).json({ message: 'Video not found' });
        const now = new Date();
        if (video.practiceEnabled === false || (video.practiceStartDate && now < video.practiceStartDate) || (video.practiceEndDate && now > video.practiceEndDate)) {
            return res.status(403).json({ message: 'Practice is not active right now' });
        }

        const existing = await VideoQuizAttempt.findOne({ userId: req.user.id, videoId });
        if (existing) {
            return res.status(409).json({ message: 'Already attempted', attempt: await buildResult(existing) });
        }

        const progress = await VideoProgress.findOne({ userId: req.user.id, videoId });
        if (!progress || !progress.completed) {
            return res.status(403).json({ message: 'Watch the video before answering' });
        }

        const questions = await VideoQuestion.find({ videoId });
        if (questions.length === 0) {
            return res.status(404).json({ message: 'This video has no questions' });
        }

        const graded = [];
        let score = 0;

        for (const question of questions) {
            const submitted = answers.find((a) => String(a.questionId) === String(question._id));
            const attempted = submitted && submitted.attemptedAnswer != null
                ? String(submitted.attemptedAnswer)
                : null;

            let isCorrect = false;
            if (attempted !== null) {
                const expected = String(question.correct_answer).trim();
                if (attempted.trim().toLowerCase() === expected.toLowerCase()) {
                    isCorrect = true;
                } else {
                    const options = readOptions(question.options_en);
                    const index = Number.parseInt(attempted, 10);
                    if (Number.isInteger(index) && options[index] !== undefined) {
                        isCorrect = String(options[index]).trim().toLowerCase() === expected.toLowerCase();
                    }
                }
            }

            if (isCorrect) score += 1;
            graded.push({
                questionId: question._id,
                attemptedAnswer: attempted,
                isCorrect
            });
        }

        const percentage = Math.round((score / questions.length) * 100);

        let attempt;
        try {
            attempt = await VideoQuizAttempt.create({
                userId: req.user.id,
                videoId,
                language: language === 'Malayalam' ? 'Malayalam' : 'English',
                answers: graded,
                score,
                totalQuestions: questions.length,
                percentage
            });
        } catch (error) {
            if (error && error.code === 11000) {
                const already = await VideoQuizAttempt.findOne({ userId: req.user.id, videoId });
                return res.status(409).json({ message: 'Already attempted', attempt: await buildResult(already) });
            }
            throw error;
        }

        await recordLearningEvent({ userId: req.user.id, type: 'video_question_completed', sourceType: 'video', sourceId: videoId, occurredAt: attempt.createdAt });

        return res.status(201).json({ message: 'Quiz submitted', attempt: await buildResult(attempt) });
    } catch (error) {
        console.error('Error submitting video quiz:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
