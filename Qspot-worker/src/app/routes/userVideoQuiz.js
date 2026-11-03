const express = require('express');
const mongoose = require('mongoose');
const VideoQuestion = require('../models/videoQuestions');
const VideoQuizAttempt = require('../models/videoQuizAttempt');
const VideoProgress = require('../models/videoProgress');
const Video = require('../models/videos');
const { authenticateUser } = require('../middlewares/auth');
const { recordLearningEvent } = require('../services/learningEvents');
const { practiceAnswersAt, answersRevealed, revealFields } = require('../services/answerReveal');
const { practiceOpen, retakeUpdate } = require('../services/practiceRetake');

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

// Per-question results for the stored (best) try. They include the correct
// answers, so they are only built once revealed.
const buildResults = async (attempt) => {
    const questions = await VideoQuestion.find({ _id: { $in: attempt.answers.map((a) => a.questionId) } });
    const byId = new Map(questions.map((q) => [String(q._id), q]));

    return attempt.answers.map((ans) => {
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
};

// What the app receives. score/percentage are the best try; `latest` is the
// most recent one (the try just submitted, after a POST).
const shapePractice = async (attempt, video, now = new Date()) => {
    const availableAt = practiceAnswersAt(video);
    const revealed = answersRevealed(availableAt, now);
    return {
        attemptId: attempt._id,
        videoId: attempt.videoId,
        language: attempt.language,
        score: attempt.score,
        totalQuestions: attempt.totalQuestions,
        percentage: attempt.percentage,
        createdAt: attempt.createdAt,
        attemptCount: Number(attempt.attemptCount) || 1,
        latest: {
            score: attempt.lastScore ?? attempt.score,
            totalQuestions: attempt.totalQuestions,
            percentage: attempt.lastPercentage ?? attempt.percentage,
            submittedAt: attempt.lastAttemptAt || attempt.createdAt
        },
        canRetake: practiceOpen(video, now),
        ...revealFields(availableAt, revealed ? await buildResults(attempt) : [], now)
    };
};

const PRACTICE_FIELDS = 'practiceEnabled practiceStartDate practiceEndDate';

// GET /api/user/video-quiz?videoId=<id> - this user's best practice result
router.get('/', authenticateUser, async (req, res) => {
    try {
        const { videoId } = req.query;
        if (!videoId || !mongoose.Types.ObjectId.isValid(videoId)) {
            return res.status(400).json({ message: 'A valid videoId is required' });
        }
        const attempt = await VideoQuizAttempt.findOne({ userId: req.user.id, videoId });
        if (!attempt) return res.json(null);
        const video = await Video.findById(videoId).select(PRACTICE_FIELDS);
        return res.json(await shapePractice(attempt, video));
    } catch (error) {
        console.error('Error fetching video quiz attempt:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/user/video-quiz - submit answers for the questions on one video.
// body: { videoId, language, answers: [{ questionId, attemptedAnswer }] }
// Can be repeated while practice is open; the best try is kept.
router.post('/', authenticateUser, async (req, res) => {
    try {
        const { videoId, language, answers } = req.body || {};

        if (!videoId || !mongoose.Types.ObjectId.isValid(videoId)) {
            return res.status(400).json({ message: 'Invalid videoId' });
        }
        if (!Array.isArray(answers) || answers.length === 0) {
            return res.status(400).json({ message: 'answers must be a non-empty array' });
        }

        const video = await Video.findById(videoId).select(PRACTICE_FIELDS);
        if (!video) return res.status(404).json({ message: 'Video not found' });
        const now = new Date();
        if (!practiceOpen(video, now)) {
            return res.status(403).json({ message: 'Practice is not active right now' });
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

            // The app sends the number of the button picked (0 = first), never
            // the option text, so compare it with the correct button's number.
            let isCorrect = false;
            if (attempted !== null && /^\d+$/.test(attempted.trim())) {
                const expectedIndex = correctIndex(question, readOptions(question.options_en));
                isCorrect = expectedIndex >= 0 && Number.parseInt(attempted, 10) === expectedIndex;
            }

            if (isCorrect) score += 1;
            graded.push({
                questionId: question._id,
                attemptedAnswer: attempted,
                isCorrect
            });
        }

        const thisTry = {
            answers: graded,
            score,
            totalQuestions: questions.length,
            percentage: Math.round((score / questions.length) * 100),
            language: language === 'Malayalam' ? 'Malayalam' : 'English'
        };

        const saveRetake = async (existing) => {
            const { improved, set } = retakeUpdate(existing, thisTry, now);
            const saved = await VideoQuizAttempt.findOneAndUpdate({ _id: existing._id }, { $set: set }, { new: true });
            return { saved, improved };
        };

        let attempt;
        let improved = true;
        const existing = await VideoQuizAttempt.findOne({ userId: req.user.id, videoId });
        if (existing) {
            ({ saved: attempt, improved } = await saveRetake(existing));
        } else {
            try {
                attempt = await VideoQuizAttempt.create({
                    userId: req.user.id,
                    videoId,
                    ...thisTry,
                    attemptCount: 1,
                    lastScore: thisTry.score,
                    lastPercentage: thisTry.percentage,
                    lastAttemptAt: now
                });
            } catch (error) {
                if (!error || error.code !== 11000) throw error;
                // Another request created the row first: count this as a retake.
                const raced = await VideoQuizAttempt.findOne({ userId: req.user.id, videoId });
                ({ saved: attempt, improved } = await saveRetake(raced));
            }
        }

        await recordLearningEvent({ userId: req.user.id, type: 'video_question_completed', sourceType: 'video', sourceId: videoId, occurredAt: now });

        return res.status(201).json({ message: 'Practice submitted', improved, attempt: await shapePractice(attempt, video, now) });
    } catch (error) {
        console.error('Error submitting video quiz:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
