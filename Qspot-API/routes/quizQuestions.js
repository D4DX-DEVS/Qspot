const express = require('express');
const mongoose = require('mongoose');
const QuizQuestion = require('../models/quizQuestions');
const { authenticateToken } = require('../middlewares/auth');

const router = express.Router();

const requiredFields = [
    'type',
    'question_en',
    'question_ml',
    'options_en',
    'options_ml',
    'correct_answer',
    'difficulty'
];

const normalizeToString = (value) => {
    if (value === undefined || value === null) {
        return null;
    }
    if (typeof value === 'string') {
        return value.trim();
    }
    if (Array.isArray(value) || typeof value === 'object') {
        return JSON.stringify(value);
    }
    return String(value).trim();
};

const buildPayload = (payload) => {
    const normalized = {};

    for (const field of requiredFields) {
        const value = normalizeToString(payload[field]);
        if (!value) {
            return { error: `${field} is required and must be a non-empty string` };
        }
        normalized[field] = value;
    }

    return { data: normalized };
};

// GET /api/quiz-questions - List all quiz questions
router.get('/', authenticateToken, async (req, res) => {
    try {
        const questions = await QuizQuestion.find().sort({ createdAt: -1 });
        res.json(questions);
    } catch (error) {
        console.error('Error fetching quiz questions:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/quiz-questions/:id - Fetch a single quiz question
router.get('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid question id' });
        }

        const question = await QuizQuestion.findById(id);
        if (!question) {
            return res.status(404).json({ message: 'Quiz question not found' });
        }

        res.json(question);
    } catch (error) {
        console.error('Error fetching quiz question:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/quiz-questions - Create a new quiz question
router.post('/', authenticateToken, async (req, res) => {
    try {
        const { data, error } = buildPayload(req.body || {});
        if (error) {
            return res.status(400).json({ message: error });
        }

        const question = await QuizQuestion.create(data);
        res.status(201).json({
            message: 'Quiz question created successfully',
            question
        });
    } catch (error) {
        console.error('Error creating quiz question:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/quiz-questions/:id - Update an existing quiz question
router.put('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid question id' });
        }

        const { data, error } = buildPayload(req.body || {});
        if (error) {
            return res.status(400).json({ message: error });
        }

        const updated = await QuizQuestion.findByIdAndUpdate(
            id,
            { $set: data },
            { new: true, runValidators: true }
        );

        if (!updated) {
            return res.status(404).json({ message: 'Quiz question not found' });
        }

        res.json({
            message: 'Quiz question updated successfully',
            question: updated
        });
    } catch (error) {
        console.error('Error updating quiz question:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/quiz-questions/:id - Delete a quiz question
router.delete('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid question id' });
        }

        const deleted = await QuizQuestion.findByIdAndDelete(id);
        if (!deleted) {
            return res.status(404).json({ message: 'Quiz question not found' });
        }

        res.json({
            message: 'Quiz question deleted successfully',
            questionId: id
        });
    } catch (error) {
        console.error('Error deleting quiz question:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;

