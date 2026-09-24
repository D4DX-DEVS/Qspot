const express = require('express');
const mongoose = require('mongoose');
const Quiz = require('../models/quiz');
const QuizConfig = require('../models/quizConfig');
const QuizQuestion = require('../models/quizQuestions');
const QuizSession = require('../models/quizSession');
const { authenticateAdmin, authenticateUser } = require('../middlewares/auth');
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

const buildResults = (attempt, questionMap) =>
    attempt.answers.map((ans) => {
        const q = questionMap.get(String(ans.questionId));
        const optionsEn = readOptions(q?.options_en);
        const optionsMl = readOptions(q?.options_ml);
        return {
            questionId: ans.questionId,
            type: q?.type || 'Multiple Choice',
            question_en: q?.question_en || '',
            question_ml: q?.question_ml || '',
            options_en: optionsEn,
            options_ml: optionsMl,
            attemptedAnswer: ans.attemptedAnswer,
            correctAnswer: q ? correctIndex(q, optionsEn) : -1,
            isCorrect: Boolean(ans.isCorrect)
        };
    });

// POST /api/quizzes/attempt (user) - grades against the session's questionIds
router.post('/attempt', authenticateUser, async (req, res) => {
    try {
        const { quizId, language, answers, totalDuration } = req.body || {};

        if (!quizId || !mongoose.Types.ObjectId.isValid(quizId)) {
            return res.status(400).json({ message: 'Invalid quizId' });
        }
        if (!Array.isArray(answers) || answers.length === 0) {
            return res.status(400).json({ message: 'answers must be a non-empty array' });
        }

        const config = await QuizConfig.findById(quizId);
        if (!config) {
            return res.status(404).json({ message: 'Quiz not found' });
        }

        const now = new Date();
        if (!config.isEnable || !(now >= new Date(config.startDate) && now <= new Date(config.endDate))) {
            return res.status(403).json({ message: 'Quiz is not live right now' });
        }

        const existingAttempt = await Quiz.findOne({ userId: req.user.id, quizId });
        if (existingAttempt) {
            const questions = await QuizQuestion.find({ _id: { $in: existingAttempt.questionIds } });
            const questionMap = new Map(questions.map((q) => [String(q._id), q]));
            return res.status(409).json({
                message: 'Already attempted',
                attempt: {
                    attemptId: existingAttempt._id,
                    quizId: existingAttempt.quizId,
                    title: config.title,
                    language: existingAttempt.language,
                    score: existingAttempt.score,
                    totalQuestions: existingAttempt.totalQuestions,
                    percentage: existingAttempt.percentage,
                    totalDuration: existingAttempt.totalDuration,
                    createdAt: existingAttempt.createdAt,
                    results: buildResults(existingAttempt, questionMap)
                }
            });
        }

        const session = await QuizSession.findOne({ userId: req.user.id, quizId });
        if (!session || session.questionIds.length === 0) {
            return res.status(400).json({ message: 'No active quiz session. Fetch the questions first.' });
        }

        const questions = await QuizQuestion.find({ _id: { $in: session.questionIds } });
        const questionMap = new Map(questions.map((q) => [String(q._id), q]));

        const gradedAnswers = [];
        let score = 0;

        for (const questionId of session.questionIds) {
            const q = questionMap.get(String(questionId));
            if (!q) continue;

            const submitted = answers.find((a) => String(a.questionId) === String(questionId));
            const optionsEn = readOptions(q.options_en);
            const expectedIndex = correctIndex(q, optionsEn);

            let attemptedIndex = null;
            let isCorrect = false;
            if (submitted && submitted.attemptedAnswer !== undefined && submitted.attemptedAnswer !== null) {
                const raw = submitted.attemptedAnswer;
                if (typeof raw === 'number' || /^-?\d+$/.test(String(raw))) {
                    attemptedIndex = Number.parseInt(raw, 10);
                } else {
                    // Accept option text (either language) and resolve it to an index.
                    const optionsMl = readOptions(q.options_ml);
                    let idx = optionsEn.findIndex((o) => o.toLowerCase() === String(raw).trim().toLowerCase());
                    if (idx < 0) idx = optionsMl.findIndex((o) => o.toLowerCase() === String(raw).trim().toLowerCase());
                    attemptedIndex = idx >= 0 ? idx : null;
                }
                isCorrect = attemptedIndex !== null && attemptedIndex === expectedIndex;
            }

            if (isCorrect) score += 1;
            gradedAnswers.push({
                questionId,
                attemptedAnswer: attemptedIndex,
                isCorrect,
                duration: Number(submitted?.duration) || 0
            });
        }

        const totalQuestions = session.questionIds.length;
        const percentage = totalQuestions > 0 ? Math.round((score / totalQuestions) * 100) : 0;

        let attempt;
        try {
            attempt = await Quiz.create({
                userId: req.user.id,
                quizId,
                language: language === 'Malayalam' ? 'Malayalam' : 'English',
                questionIds: session.questionIds,
                answers: gradedAnswers,
                score,
                totalQuestions,
                percentage,
                totalDuration: Number(totalDuration) || 0
            });
        } catch (error) {
            if (error && error.code === 11000) {
                return res.status(409).json({ message: 'Already attempted' });
            }
            throw error;
        }

        await QuizSession.deleteOne({ userId: req.user.id, quizId });
        await recordLearningEvent({ userId: req.user.id, type: 'quiz_completed', sourceType: 'quiz', sourceId: quizId, occurredAt: attempt.createdAt });

        return res.status(201).json({
            message: 'Quiz attempt submitted',
            attempt: {
                attemptId: attempt._id,
                quizId: attempt.quizId,
                title: config.title,
                language: attempt.language,
                score: attempt.score,
                totalQuestions: attempt.totalQuestions,
                percentage: attempt.percentage,
                totalDuration: attempt.totalDuration,
                createdAt: attempt.createdAt,
                results: buildResults(attempt, questionMap)
            }
        });
    } catch (error) {
        console.error('Error submitting quiz attempt:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/quizzes/attempt/:attemptId - Admin deletes a specific quiz attempt
router.delete('/attempt/:attemptId', authenticateAdmin, async (req, res) => {
    try {
        const { attemptId } = req.params;

        const attempt = await Quiz.findByIdAndDelete(attemptId);
        if (!attempt) {
            return res.status(404).json({ message: 'Quiz attempt not found' });
        }

        return res.json({ message: 'Quiz attempt deleted successfully', id: attemptId });
    } catch (error) {
        console.error('Error deleting quiz attempt:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/quizzes/attempt/:attemptId - Admin: full details of a specific quiz attempt
router.get('/attempt/:attemptId', authenticateAdmin, async (req, res) => {
    try {
        const { attemptId } = req.params;

        const attempt = await Quiz.findById(attemptId)
            .populate({ path: 'userId', select: 'name class email' })
            .populate({ path: 'quizId', select: 'title' });

        if (!attempt) {
            return res.status(404).json({ message: 'Quiz attempt not found' });
        }

        const questions = await QuizQuestion.find({ _id: { $in: attempt.questionIds } });
        const questionMap = new Map(questions.map((q) => [String(q._id), q]));

        return res.json({
            attemptId: attempt._id,
            quizId: attempt.quizId?._id || attempt.quizId,
            title: attempt.quizId?.title || 'Quiz',
            user: {
                id: attempt.userId?._id || attempt.userId,
                name: attempt.userId?.name || 'Unknown',
                class: attempt.userId?.class || null,
                email: attempt.userId?.email || null
            },
            language: attempt.language || 'English',
            score: Number(attempt.score) || 0,
            totalQuestions: Number(attempt.totalQuestions) || 0,
            percentage: Number(attempt.percentage) || 0,
            totalDuration: Number(attempt.totalDuration) || 0,
            createdAt: attempt.createdAt,
            results: buildResults(attempt, questionMap)
        });
    } catch (error) {
        console.error('Error fetching quiz attempt details:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
