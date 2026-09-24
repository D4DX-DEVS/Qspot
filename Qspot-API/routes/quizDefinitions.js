const express = require('express');
const mongoose = require('mongoose');
const QuizConfig = require('../models/quizConfig');
const QuizQuestion = require('../models/quizQuestions');
const QuizSession = require('../models/quizSession');
const Quiz = require('../models/quiz');
const { authenticateAdmin } = require('../middlewares/auth');

const router = express.Router();

const validatePositiveNumberField = (value, fieldName) => {
    if (value === undefined || value === null) {
        return null;
    }
    if (typeof value !== 'number' || !Number.isFinite(value) || value <= 0) {
        return `${fieldName} must be a number greater than 0`;
    }
    return null;
};

const validateOptionsCount = (value) => {
    if (value === undefined || value === null) {
        return null;
    }
    if (typeof value !== 'number' || !Number.isInteger(value) || value <= 0) {
        return 'optionsCount must be an integer greater than 0';
    }
    return null;
};

const normalizeTimerMode = (value) =>
    ['none', 'overall', 'per-question', 'both'].includes(value) ? value : 'none';
const normalizeClasses = (value) => Array.isArray(value)
    ? value.map((item) => String(item).trim()).filter(Boolean).slice(0, 50)
    : String(value || '').split(',').map((item) => item.trim()).filter(Boolean).slice(0, 50);

// GET /api/quiz-definitions - List quizzes, paginated (admin only)
router.get('/', authenticateAdmin, async (req, res) => {
    try {
        const page = Math.max(1, parseInt(req.query.page, 10) || 1);
        const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));

        const [items, total] = await Promise.all([
            QuizConfig.find()
                .sort({ createdAt: -1 })
                .skip((page - 1) * limit)
                .limit(limit)
                .lean(),
            QuizConfig.countDocuments({})
        ]);

        const quizIds = items.map((q) => q._id);
        const [questionCounts, attemptCounts] = await Promise.all([
            QuizQuestion.aggregate([
                { $match: { quizId: { $in: quizIds } } },
                { $group: { _id: '$quizId', count: { $sum: 1 } } }
            ]),
            Quiz.aggregate([
                { $match: { quizId: { $in: quizIds } } },
                { $group: { _id: '$quizId', count: { $sum: 1 } } }
            ])
        ]);
        const questionCountMap = new Map(questionCounts.map((c) => [String(c._id), c.count]));
        const attemptCountMap = new Map(attemptCounts.map((c) => [String(c._id), c.count]));

        const shaped = items.map((q) => ({
            ...q,
            questionCount: questionCountMap.get(String(q._id)) || 0,
            attemptCount: attemptCountMap.get(String(q._id)) || 0
        }));

        res.json({ items: shaped, total, page, limit });
    } catch (error) {
        console.error('Error fetching quizzes:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/quiz-definitions/:id - Get a single quiz (admin only)
router.get('/:id', authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid quiz id' });
        }
        const quiz = await QuizConfig.findById(id);
        if (!quiz) {
            return res.status(404).json({ message: 'Quiz not found' });
        }
        res.json(quiz);
    } catch (error) {
        console.error('Error fetching quiz:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/quiz-definitions - Create a quiz (admin only)
router.post('/', authenticateAdmin, async (req, res) => {
    try {
        const {
            title,
            assessmentType,
            startDate,
            endDate,
            numberOfQuestions,
            questionsRandomization,
            isEnable,
            overallTimeLimit,
            perQuestionTimeLimit,
            timerMode,
            allowedClasses,
            conditions,
            optionsCount
        } = req.body || {};

        if (!title || !title.trim()) {
            return res.status(400).json({ message: 'title is required' });
        }
        if (!startDate || !endDate) {
            return res.status(400).json({ message: 'startDate and endDate are required' });
        }
        if (new Date(startDate) >= new Date(endDate)) {
            return res.status(400).json({ message: 'startDate must be before endDate' });
        }
        if (numberOfQuestions === undefined || numberOfQuestions === null || numberOfQuestions < 1) {
            return res.status(400).json({ message: 'numberOfQuestions must be at least 1' });
        }

        const overallTimeLimitError = validatePositiveNumberField(overallTimeLimit, 'overallTimeLimit');
        if (overallTimeLimitError) {
            return res.status(400).json({ message: overallTimeLimitError });
        }
        const perQuestionTimeLimitError = validatePositiveNumberField(perQuestionTimeLimit, 'perQuestionTimeLimit');
        if (perQuestionTimeLimitError) {
            return res.status(400).json({ message: perQuestionTimeLimitError });
        }
        const optionsCountError = validateOptionsCount(optionsCount);
        if (optionsCountError) {
            return res.status(400).json({ message: optionsCountError });
        }

        const mode = normalizeTimerMode(timerMode);
        if ((mode === 'overall' || mode === 'both') && !(Number(overallTimeLimit) > 0)) {
            return res.status(400).json({ message: 'Overall timer is required for this timer mode' });
        }
        if ((mode === 'per-question' || mode === 'both') && !(Number(perQuestionTimeLimit) > 0)) {
            return res.status(400).json({ message: 'Per-question timer is required for this timer mode' });
        }

        const quiz = await QuizConfig.create({
            title: title.trim(),
            assessmentType: assessmentType === 'practical' ? 'practical' : 'quiz',
            startDate,
            endDate,
            numberOfQuestions,
            questionsRandomization: Boolean(questionsRandomization),
            isEnable: Boolean(isEnable),
            overallTimeLimit: overallTimeLimit ?? null,
            perQuestionTimeLimit: perQuestionTimeLimit ?? null,
            timerMode: mode,
            allowedClasses: normalizeClasses(allowedClasses),
            conditions: conditions && typeof conditions === 'object' ? conditions : {},
            optionsCount: optionsCount ?? null
        });

        res.status(201).json({ message: 'Quiz created successfully', quiz });
    } catch (error) {
        console.error('Error creating quiz:', error);
        if (error.message.includes('required') || error.message.includes('before endDate')) {
            return res.status(400).json({ message: error.message });
        }
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/quiz-definitions/:id - Update a quiz (admin only)
router.put('/:id', authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid quiz id' });
        }

        const existing = await QuizConfig.findById(id);
        if (!existing) {
            return res.status(404).json({ message: 'Quiz not found' });
        }

        const {
            title,
            assessmentType,
            startDate,
            endDate,
            numberOfQuestions,
            questionsRandomization,
            isEnable,
            overallTimeLimit,
            perQuestionTimeLimit,
            timerMode,
            allowedClasses,
            conditions,
            optionsCount
        } = req.body || {};

        const finalStart = startDate !== undefined ? new Date(startDate) : existing.startDate;
        const finalEnd = endDate !== undefined ? new Date(endDate) : existing.endDate;
        if (finalStart >= finalEnd) {
            return res.status(400).json({ message: 'startDate must be before endDate' });
        }

        if (title !== undefined && (title === null || !title.trim())) {
            return res.status(400).json({ message: 'title must be a non-empty string' });
        }

        const overallTimeLimitError = validatePositiveNumberField(overallTimeLimit, 'overallTimeLimit');
        if (overallTimeLimitError) {
            return res.status(400).json({ message: overallTimeLimitError });
        }
        const perQuestionTimeLimitError = validatePositiveNumberField(perQuestionTimeLimit, 'perQuestionTimeLimit');
        if (perQuestionTimeLimitError) {
            return res.status(400).json({ message: perQuestionTimeLimitError });
        }
        const optionsCountError = validateOptionsCount(optionsCount);
        if (optionsCountError) {
            return res.status(400).json({ message: optionsCountError });
        }

        const mode = timerMode === undefined ? (existing.timerMode || 'none') : normalizeTimerMode(timerMode);
        const overall = overallTimeLimit === undefined ? existing.overallTimeLimit : overallTimeLimit;
        const perQuestion = perQuestionTimeLimit === undefined ? existing.perQuestionTimeLimit : perQuestionTimeLimit;
        if ((mode === 'overall' || mode === 'both') && !(Number(overall) > 0)) {
            return res.status(400).json({ message: 'Overall timer is required for this timer mode' });
        }
        if ((mode === 'per-question' || mode === 'both') && !(Number(perQuestion) > 0)) {
            return res.status(400).json({ message: 'Per-question timer is required for this timer mode' });
        }

        const updateData = { $set: {} };
        if (title !== undefined) updateData.$set.title = title.trim();
        if (assessmentType !== undefined) {
            if (!['quiz', 'practical'].includes(assessmentType)) return res.status(400).json({ message: 'assessmentType must be quiz or practical' });
            updateData.$set.assessmentType = assessmentType;
        }
        if (startDate !== undefined) updateData.$set.startDate = startDate;
        if (endDate !== undefined) updateData.$set.endDate = endDate;
        if (numberOfQuestions !== undefined) updateData.$set.numberOfQuestions = numberOfQuestions;
        if (questionsRandomization !== undefined) updateData.$set.questionsRandomization = Boolean(questionsRandomization);
        if (isEnable !== undefined) updateData.$set.isEnable = Boolean(isEnable);
        if (overallTimeLimit !== undefined) updateData.$set.overallTimeLimit = overallTimeLimit;
        if (perQuestionTimeLimit !== undefined) updateData.$set.perQuestionTimeLimit = perQuestionTimeLimit;
        if (timerMode !== undefined) updateData.$set.timerMode = mode;
        if (allowedClasses !== undefined) updateData.$set.allowedClasses = normalizeClasses(allowedClasses);
        if (conditions !== undefined) updateData.$set.conditions = conditions && typeof conditions === 'object' ? conditions : {};
        if (optionsCount !== undefined) updateData.$set.optionsCount = optionsCount;

        const updated = await QuizConfig.findByIdAndUpdate(id, updateData, {
            new: true,
            runValidators: true
        });

        res.json({ message: 'Quiz updated successfully', quiz: updated });
    } catch (error) {
        console.error('Error updating quiz:', error);
        if (error.message.includes('before endDate')) {
            return res.status(400).json({ message: error.message });
        }
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/quiz-definitions/:id - Delete a quiz and cascade (admin only)
router.delete('/:id', authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid quiz id' });
        }

        const existing = await QuizConfig.findByIdAndDelete(id);
        if (!existing) {
            return res.status(404).json({ message: 'Quiz not found' });
        }

        await Promise.all([
            QuizQuestion.deleteMany({ quizId: id }),
            QuizSession.deleteMany({ quizId: id }),
            Quiz.deleteMany({ quizId: id })
        ]);

        res.json({ message: 'Quiz deleted successfully', id });
    } catch (error) {
        console.error('Error deleting quiz:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/quiz-definitions/:id/results?minScore&maxScore&from&to&page&limit&search (admin only)
router.get('/:id/results', authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid quiz id' });
        }
        const quiz = await QuizConfig.findById(id);
        if (!quiz) {
            return res.status(404).json({ message: 'Quiz not found' });
        }

        const { minScore, maxScore, from, to, search } = req.query;
        const filter = { quizId: id };

        if (minScore !== undefined || maxScore !== undefined) {
            filter.score = {};
            if (minScore !== undefined) filter.score.$gte = Number(minScore);
            if (maxScore !== undefined) filter.score.$lte = Number(maxScore);
        }

        if (from !== undefined || to !== undefined) {
            filter.createdAt = {};
            if (from !== undefined) filter.createdAt.$gte = new Date(from);
            if (to !== undefined) filter.createdAt.$lte = new Date(to);
        }

        const page = Math.max(1, parseInt(req.query.page, 10) || 1);
        const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));

        let attempts = await Quiz.find(filter)
            .populate({ path: 'userId', select: 'name class' })
            .sort({ score: -1, totalDuration: 1 });

        if (search) {
            const re = new RegExp(String(search).trim(), 'i');
            attempts = attempts.filter((a) => re.test(a.userId?.name || '') || re.test(a.userId?.class || ''));
        }

        const total = attempts.length;
        const page_ = attempts.slice((page - 1) * limit, page * limit);

        const results = page_.map((attempt, index) => ({
            rank: (page - 1) * limit + index + 1,
            attemptId: attempt._id,
            userId: attempt.userId?._id || attempt.userId,
            name: attempt.userId?.name || 'Unknown',
            class: attempt.userId?.class || null,
            score: Number(attempt.score) || 0,
            totalQuestions: Number(attempt.totalQuestions) || 0,
            percentage: Number(attempt.percentage) || 0,
            duration: Number(attempt.totalDuration) || 0,
            createdAt: attempt.createdAt
        }));

        res.json({ quizId: id, title: quiz.title, items: results, total, page, limit });
    } catch (error) {
        console.error('Error fetching quiz results:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
