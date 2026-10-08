const express = require('express');
const mongoose = require('mongoose');
const QuizConfig = require('../models/quizConfig');
const QuizQuestion = require('../models/quizQuestions');
const QuizSession = require('../models/quizSession');
const Quiz = require('../models/quiz');
const VideoProgress = require('../models/videoProgress');
const { authenticateUser } = require('../middlewares/auth');

const router = express.Router();

const QUESTION_FIELDS = 'type question_en question_ml options_en options_ml difficulty';

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

const statusOf = (quiz, now = new Date()) => {
    if (now < new Date(quiz.startDate)) return 'upcoming';
    if (now > new Date(quiz.endDate)) return 'ended';
    return 'live';
};

const isAccessible = async (quiz, user) => {
    const allowed = Array.isArray(quiz.allowedClasses) ? quiz.allowedClasses.filter(Boolean) : [];
    if (allowed.length > 0 && !allowed.includes(String(user.class || ''))) return false;
    if (quiz.conditions?.requireCompletedVideo) {
        const completed = await VideoProgress.exists({ userId: user.id, completed: true });
        if (!completed) return false;
    }
    return true;
};

// Certificate settings as they apply to this student. Uses the same class
// match as issuance in routes/certificates.js (trimmed, case-insensitive), so
// the app never promises a certificate the issue batch would skip.
const certificateFor = (quiz, user) => {
    const config = quiz.certificate;
    if (!config?.enabled) return { enabled: false, minimumPercentage: 0 };
    const classes = (config.eligibleClasses || [])
        .map((value) => String(value).trim().toLowerCase())
        .filter(Boolean);
    const userClass = String(user?.class || '').trim().toLowerCase();
    if (classes.length > 0 && !classes.includes(userClass)) {
        return { enabled: false, minimumPercentage: 0 };
    }
    return { enabled: true, minimumPercentage: Number(config.minimumPercentage) || 0 };
};

const shapeQuiz = (quiz, questionCount, myAttempt, user) => ({
    _id: quiz._id,
    title: quiz.title,
    assessmentType: quiz.assessmentType || 'quiz',
    startDate: quiz.startDate,
    endDate: quiz.endDate,
    numberOfQuestions: quiz.numberOfQuestions,
    questionsRandomization: quiz.questionsRandomization,
    overallTimeLimit: quiz.overallTimeLimit,
    perQuestionTimeLimit: quiz.perQuestionTimeLimit,
    timerMode: quiz.timerMode || 'none',
    allowedClasses: quiz.allowedClasses || [],
    conditions: quiz.conditions || {},
    optionsCount: quiz.optionsCount,
    status: statusOf(quiz),
    certificate: certificateFor(quiz, user),
    questionCount,
    myAttempt: myAttempt
        ? {
              attemptId: myAttempt._id,
              score: myAttempt.score,
              totalQuestions: myAttempt.totalQuestions,
              percentage: myAttempt.percentage,
              createdAt: myAttempt.createdAt
          }
        : null
});

// GET /api/user-quizzes (user) - enabled quizzes, live first, then upcoming, then recently-ended
router.get('/', authenticateUser, async (req, res) => {
    try {
        const now = new Date();
        const endedSince = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

        const quizzes = (await QuizConfig.find({
            isEnable: true,
            $or: [{ endDate: { $gte: endedSince } }]
        }).sort({ startDate: -1 }));
        const accessibleQuizzes = [];
        for (const quiz of quizzes) if (await isAccessible(quiz, req.user)) accessibleQuizzes.push(quiz);

        const quizIds = accessibleQuizzes.map((q) => q._id);
        const [counts, attempts] = await Promise.all([
            QuizQuestion.aggregate([
                { $match: { quizId: { $in: quizIds } } },
                { $group: { _id: '$quizId', count: { $sum: 1 } } }
            ]),
            Quiz.find({ userId: req.user.id, quizId: { $in: quizIds } })
        ]);
        const countMap = new Map(counts.map((c) => [String(c._id), c.count]));
        const attemptMap = new Map(attempts.map((a) => [String(a.quizId), a]));

        const shaped = accessibleQuizzes.map((q) =>
            shapeQuiz(q, countMap.get(String(q._id)) || 0, attemptMap.get(String(q._id)), req.user)
        );

        const rank = { live: 0, upcoming: 1, ended: 2 };
        shaped.sort((a, b) => {
            if (rank[a.status] !== rank[b.status]) return rank[a.status] - rank[b.status];
            if (a.status === 'upcoming') return new Date(a.startDate) - new Date(b.startDate);
            return new Date(b.startDate) - new Date(a.startDate);
        });

        res.json(shaped);
    } catch (error) {
        console.error('Error fetching user quizzes:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/user-quizzes/:id (user)
router.get('/:id', authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid quiz ID' });
        }

        const quiz = await QuizConfig.findOne({ _id: id, isEnable: true });
        if (!quiz || !(await isAccessible(quiz, req.user))) {
            return res.status(404).json({ message: 'Quiz not found' });
        }

        const [questionCount, myAttempt] = await Promise.all([
            QuizQuestion.countDocuments({ quizId: id }),
            Quiz.findOne({ userId: req.user.id, quizId: id })
        ]);

        res.json(shapeQuiz(quiz, questionCount, myAttempt, req.user));
    } catch (error) {
        console.error('Error fetching user quiz:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/user-quizzes/:id/questions (user) - starts/resumes a quizSession
router.get('/:id/questions', authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid quiz ID' });
        }

        const quiz = await QuizConfig.findOne({ _id: id, isEnable: true });
        if (!quiz || !(await isAccessible(quiz, req.user))) {
            return res.status(404).json({ message: 'Quiz not found' });
        }

        const now = new Date();
        if (statusOf(quiz, now) !== 'live') {
            return res.status(403).json({ message: 'Quiz is not live right now' });
        }

        const existingAttempt = await Quiz.findOne({ userId: req.user.id, quizId: id });
        if (existingAttempt) {
            return res.status(409).json({ message: 'Already attempted' });
        }

        // Repeat calls return the SAME set of questions: read the session back
        // if one exists instead of re-selecting.
        let session = await QuizSession.findOne({ userId: req.user.id, quizId: id });

        if (!session) {
            const pool = await QuizQuestion.find({ quizId: id }).select('_id');
            let selected = pool.map((q) => q._id);

            if (quiz.questionsRandomization) {
                for (let i = selected.length - 1; i > 0; i--) {
                    const j = Math.floor(Math.random() * (i + 1));
                    [selected[i], selected[j]] = [selected[j], selected[i]];
                }
            }
            selected = selected.slice(0, quiz.numberOfQuestions);

            try {
                session = await QuizSession.create({
                    userId: req.user.id,
                    quizId: id,
                    questionIds: selected,
                    startedAt: now
                });
            } catch (error) {
                if (error && error.code === 11000) {
                    session = await QuizSession.findOne({ userId: req.user.id, quizId: id });
                } else {
                    throw error;
                }
            }
        }

        const questions = await QuizQuestion.find({ _id: { $in: session.questionIds } }).select(QUESTION_FIELDS);
        const byId = new Map(questions.map((q) => [String(q._id), q]));
        const ordered = session.questionIds.map((qid) => byId.get(String(qid))).filter(Boolean);

        res.json({
            quizId: quiz._id,
            title: quiz.title,
            assessmentType: quiz.assessmentType || 'quiz',
            overallTimeLimit: quiz.overallTimeLimit,
            perQuestionTimeLimit: quiz.perQuestionTimeLimit,
            timerMode: quiz.timerMode || 'none',
            questions: ordered.map((q) => ({
                _id: q._id,
                type: q.type,
                question_en: q.question_en,
                question_ml: q.question_ml,
                options_en: readOptions(q.options_en),
                options_ml: readOptions(q.options_ml),
                difficulty: q.difficulty
            }))
        });
    } catch (error) {
        console.error('Error fetching user quiz questions:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
