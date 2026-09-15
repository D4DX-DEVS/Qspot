const express = require('express');
const mongoose = require('mongoose');
const QuizConfig = require('../models/quizConfig');
const QuizQuestion = require('../models/quizQuestions');
const Quiz = require('../models/quiz');
const { authenticateToken } = require('../middlewares/auth');

const router = express.Router();

// Same rule used by routes/quizzes.js to identify the one pre-existing
// legacy quiz configuration document (no real title, stored as null).
const isLegacyQuiz = (quiz) => !quiz.title;

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

// GET /api/quiz-definitions - List quizzes, paginated (admin only)
router.get('/', authenticateToken, async (req, res) => {
    try {
        const page = Math.max(1, parseInt(req.query.page, 10) || 1);
        const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));

        const [items, total] = await Promise.all([
            QuizConfig.find()
                .sort({ createdAt: -1 })
                .skip((page - 1) * limit)
                .limit(limit),
            QuizConfig.countDocuments({})
        ]);

        res.json({ items, total, page, limit });
    } catch (error) {
        console.error('Error fetching quizzes:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/quiz-definitions/:id - Get a single quiz (admin only)
router.get('/:id', authenticateToken, async (req, res) => {
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
router.post('/', authenticateToken, async (req, res) => {
    try {
        const {
            title,
            startDate,
            endDate,
            numberOfQuestions,
            questionsRandomization,
            isEnable,
            overallTimeLimit,
            perQuestionTimeLimit,
            optionsCount
        } = req.body;

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

        const quiz = await QuizConfig.create({
            title: title.trim(),
            startDate,
            endDate,
            numberOfQuestions,
            questionsRandomization: Boolean(questionsRandomization),
            isEnable: Boolean(isEnable),
            overallTimeLimit: overallTimeLimit ?? null,
            perQuestionTimeLimit: perQuestionTimeLimit ?? null,
            optionsCount: optionsCount ?? null
        });

        res.status(201).json({
            message: 'Quiz created successfully',
            quiz
        });
    } catch (error) {
        console.error('Error creating quiz:', error);
        if (error.message.includes('required') || error.message.includes('before endDate')) {
            return res.status(400).json({ message: error.message });
        }
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/quiz-definitions/:id - Update a quiz (admin only)
router.put('/:id', authenticateToken, async (req, res) => {
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
            startDate,
            endDate,
            numberOfQuestions,
            questionsRandomization,
            isEnable,
            overallTimeLimit,
            perQuestionTimeLimit,
            optionsCount
        } = req.body;

        const finalStart = startDate !== undefined ? new Date(startDate) : existing.startDate;
        const finalEnd = endDate !== undefined ? new Date(endDate) : existing.endDate;
        if (finalStart >= finalEnd) {
            return res.status(400).json({ message: 'startDate must be before endDate' });
        }

        if (title !== undefined) {
            if (isLegacyQuiz(existing)) {
                return res.status(400).json({ message: 'The legacy quiz cannot have its title changed.' });
            }
            if (title === null || !title.trim()) {
                return res.status(400).json({ message: 'title must be a non-empty string' });
            }
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

        const updateData = { $set: {} };
        if (title !== undefined) updateData.$set.title = title.trim();
        if (startDate !== undefined) updateData.$set.startDate = startDate;
        if (endDate !== undefined) updateData.$set.endDate = endDate;
        if (numberOfQuestions !== undefined) updateData.$set.numberOfQuestions = numberOfQuestions;
        if (questionsRandomization !== undefined) updateData.$set.questionsRandomization = Boolean(questionsRandomization);
        if (isEnable !== undefined) updateData.$set.isEnable = Boolean(isEnable);
        if (overallTimeLimit !== undefined) updateData.$set.overallTimeLimit = overallTimeLimit;
        if (perQuestionTimeLimit !== undefined) updateData.$set.perQuestionTimeLimit = perQuestionTimeLimit;
        if (optionsCount !== undefined) updateData.$set.optionsCount = optionsCount;

        const updated = await QuizConfig.findByIdAndUpdate(id, updateData, {
            new: true,
            runValidators: true
        });

        res.json({
            message: 'Quiz updated successfully',
            quiz: updated
        });
    } catch (error) {
        console.error('Error updating quiz:', error);
        if (error.message.includes('before endDate')) {
            return res.status(400).json({ message: error.message });
        }
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/quiz-definitions/:id - Delete a quiz (admin only)
router.delete('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid quiz id' });
        }

        const existing = await QuizConfig.findById(id);
        if (!existing) {
            return res.status(404).json({ message: 'Quiz not found' });
        }
        if (isLegacyQuiz(existing)) {
            return res.status(400).json({ message: 'The legacy quiz cannot be deleted.' });
        }

        const deleted = await QuizConfig.findByIdAndDelete(id);

        res.json({
            message: 'Quiz deleted successfully',
            quizId: id
        });
    } catch (error) {
        console.error('Error deleting quiz:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/quiz-definitions/:id/questions - Questions scoped to this quiz (admin only)
router.get('/:id/questions', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid quiz id' });
        }
        const quizExists = await QuizConfig.exists({ _id: id });
        if (!quizExists) {
            return res.status(404).json({ message: 'Quiz not found' });
        }
        const page = Math.max(1, parseInt(req.query.page, 10) || 1);
        const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));

        const [items, total] = await Promise.all([
            QuizQuestion.find({ quizId: id })
                .select('type question_en question_ml difficulty quizId createdAt')
                .sort({ createdAt: -1 })
                .skip((page - 1) * limit)
                .limit(limit),
            QuizQuestion.countDocuments({ quizId: id })
        ]);

        res.json({ items, total, page, limit });
    } catch (error) {
        console.error('Error fetching quiz questions:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/quiz-definitions/:id/results - Results scoped to this quiz, with time/score filters (admin only)
router.get('/:id/results', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid quiz id' });
        }
        const quizExists = await QuizConfig.exists({ _id: id });
        if (!quizExists) {
            return res.status(404).json({ message: 'Quiz not found' });
        }

        const { minScore, maxScore, from, to } = req.query;
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

        // Ranking: higher score wins; when scores tie, less time taken wins.
        const [attempts, total] = await Promise.all([
            Quiz.find(filter)
                .populate({ path: 'userId', select: 'name class' })
                .sort({ score: -1, totalDuration: 1 })
                .skip((page - 1) * limit)
                .limit(limit),
            Quiz.countDocuments(filter)
        ]);

        const results = attempts.map((attempt, index) => ({
            rank: (page - 1) * limit + index + 1,
            attemptId: attempt._id,
            userId: attempt.userId?._id || attempt.userId,
            name: attempt.userId?.name || 'Unknown',
            class: attempt.userId?.class || null,
            score: Number(attempt.score) || 0,
            percentage: Number(attempt.percentage) || 0,
            duration: Number(attempt.totalDuration) || 0,
            createdAt: attempt.createdAt
        }));

        res.json({
            quizId: id,
            items: results,
            total,
            page,
            limit
        });
    } catch (error) {
        console.error('Error fetching quiz results:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
