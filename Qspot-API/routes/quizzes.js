const express = require('express');
const mongoose = require('mongoose');
const Quiz = require('../models/quiz');
const QuizConfig = require('../models/quizConfig');
const QuizQuestion = require('../models/quizQuestions');
const QuizSession = require('../models/quizSession');
const { authenticateAdmin, authenticateUser } = require('../middlewares/auth');
const { recordLearningEvent } = require('../services/learningEvents');
const { submissionWindow } = require('../services/quizWindow');
const { assessTiming } = require('../services/quizTiming');
const { examAnswersAt, revealFields } = require('../services/answerReveal');

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
            isCorrect: Boolean(ans.isCorrect),
            status: ans.status || null,
            duration: Number(ans.duration) || 0,
            lateAnswer: ans.lateAnswer ?? null
        };
    });

// The attempt as the app receives it: after grading (201) or on a repeat (409).
// Per-question results carry the correct answers, so they are only included
// once the exam has closed for everyone.
const shapeAttempt = (attempt, config, questionMap) => ({
    attemptId: attempt._id,
    quizId: attempt.quizId,
    title: config.title,
    language: attempt.language || 'English',
    score: attempt.score,
    totalQuestions: attempt.totalQuestions,
    percentage: attempt.percentage,
    totalDuration: attempt.totalDuration,
    createdAt: attempt.createdAt,
    ...revealFields(examAnswersAt(config), buildResults(attempt, questionMap))
});

// POST /api/quizzes/attempt (user) - grades against the session's questionIds.
// Safe to repeat: the app retries a submission until it hears back, so a second
// call for the same student + quiz never grades twice; it returns the saved
// attempt with 409.
router.post('/attempt', authenticateUser, async (req, res) => {
    try {
        const { quizId, language, answers, totalDuration } = req.body || {};

        if (!quizId || !mongoose.Types.ObjectId.isValid(quizId)) {
            return res.status(400).json({ message: 'Invalid quizId' });
        }
        if (!Array.isArray(answers) || answers.length === 0) {
            return res.status(400).json({ message: 'answers must be a non-empty array' });
        }

        const config = await QuizConfig.findById(quizId).lean();
        if (!config) {
            return res.status(404).json({ message: 'Quiz not found', code: 'QUIZ_NOT_FOUND' });
        }

        const [existingAttempt, session] = await Promise.all([
            Quiz.findOne({ userId: req.user.id, quizId }).lean(),
            QuizSession.findOne({ userId: req.user.id, quizId }).lean()
        ]);

        // Checked before the time window: a retry of a submission the server
        // already saved must get its result back even after the quiz closed.
        if (existingAttempt) {
            const questions = await QuizQuestion.find({ _id: { $in: existingAttempt.questionIds } }).lean();
            const questionMap = new Map(questions.map((q) => [String(q._id), q]));
            return res.status(409).json({
                message: 'Already attempted',
                attempt: shapeAttempt(existingAttempt, config, questionMap)
            });
        }

        // A finished quiz still takes answers from a student who started it
        // while it was live (the session proves that) for a short grace period.
        const window = submissionWindow(config, new Date());
        if (window === 'ended' && session) {
            // Started in time, but the answers arrived after the grace period
            // (e.g. sent when the phone came back online). The app shows a
            // clear "too late" message for this code.
            return res.status(403).json({
                message: "This quiz has closed. Answers that arrive after it closes can't be marked.",
                code: 'QUIZ_CLOSED',
                endDate: config.endDate
            });
        }
        if (window !== 'open' && !(window === 'grace' && session)) {
            // The app tells the student why their answers were not taken.
            return res.status(403).json({
                message: 'Quiz is not live right now',
                ...(config.isEnable ? {} : { code: 'QUIZ_DISABLED' })
            });
        }

        if (!session || session.questionIds.length === 0) {
            return res.status(400).json({ message: 'No active quiz session. Fetch the questions first.', code: 'NO_SESSION' });
        }

        const questions = await QuizQuestion.find({ _id: { $in: session.questionIds } }).lean();
        const questionMap = new Map(questions.map((q) => [String(q._id), q]));

        // Resolve what the student picked for every served question first;
        // the timing check below decides which of those answers still count.
        const served = [];
        for (const questionId of session.questionIds) {
            const q = questionMap.get(String(questionId));
            if (!q) continue;

            const submitted = answers.find((a) => String(a?.questionId) === String(questionId));
            const optionsEn = readOptions(q.options_en);
            const expectedIndex = correctIndex(q, optionsEn);

            let attemptedIndex = null;
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
            }
            served.push({ questionId, submitted, attemptedIndex, expectedIndex });
        }

        // Questions deleted since the session was saved are skipped above, so
        // they must not count toward the total either.
        if (served.length === 0) {
            return res.status(400).json({ message: 'The questions in this quiz have changed. Please reopen it.', code: 'QUESTIONS_CHANGED' });
        }

        const timing = assessTiming({
            config,
            startedAt: session.startedAt,
            receivedAt: new Date(),
            totalDuration,
            entries: served.map(({ submitted, attemptedIndex }) => ({ attemptedIndex, submitted }))
        });

        let score = 0;
        const gradedAnswers = served.map(({ questionId, attemptedIndex, expectedIndex }, i) => {
            const t = timing.answers[i];
            // An answer given after the time ran out is not graded.
            const counted = t.voided ? null : attemptedIndex;
            const isCorrect = counted !== null && counted === expectedIndex;
            if (isCorrect) score += 1;
            return {
                questionId,
                attemptedAnswer: counted,
                isCorrect,
                duration: t.duration,
                status: t.status,
                lateAnswer: t.voided ? attemptedIndex : null
            };
        });
        const totalQuestions = gradedAnswers.length;
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
                totalDuration: timing.totalDuration,
                startedAt: session.startedAt || null
            });
        } catch (error) {
            if (error && error.code === 11000) {
                // A retry raced the original request and the original won.
                const saved = await Quiz.findOne({ userId: req.user.id, quizId }).lean();
                return res.status(409).json({
                    message: 'Already attempted',
                    ...(saved ? { attempt: shapeAttempt(saved, config, questionMap) } : {})
                });
            }
            throw error;
        }

        // The attempt is saved. These follow-up writes must not turn a stored
        // submission into an error response (the app would retry for nothing).
        const followUps = await Promise.allSettled([
            QuizSession.deleteOne({ userId: req.user.id, quizId }),
            recordLearningEvent({ userId: req.user.id, type: 'quiz_completed', sourceType: 'quiz', sourceId: quizId, occurredAt: attempt.createdAt })
        ]);
        followUps.forEach((result) => {
            if (result.status === 'rejected') console.error('Quiz follow-up write failed:', result.reason);
        });

        return res.status(201).json({
            message: 'Quiz attempt submitted',
            attempt: shapeAttempt(attempt, config, questionMap)
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
            startedAt: attempt.startedAt || null,
            results: buildResults(attempt, questionMap)
        });
    } catch (error) {
        console.error('Error fetching quiz attempt details:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
