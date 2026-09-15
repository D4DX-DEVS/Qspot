const express = require('express');
const mongoose = require('mongoose');
const QuizConfig = require('../models/quizConfig');
const QuizQuestion = require('../models/quizQuestions');

const router = express.Router();

const QUIZ_FIELDS = 'title startDate endDate overallTimeLimit perQuestionTimeLimit optionsCount numberOfQuestions questionsRandomization isEnable';
const QUESTION_FIELDS = 'type question_en question_ml options_en options_ml difficulty';

// Excludes the legacy quiz, which has no real title (stored as null).
const NON_LEGACY_FILTER = { title: { $exists: true, $ne: null } };

const buildAvailabilityFilter = () => {
    const now = new Date();
    return {
        isEnable: true,
        startDate: { $lte: now },
        endDate: { $gte: now }
    };
};

// GET /api/user-quizzes/:id/questions - Questions for one available quiz (public)
// Registered before /:id so Express doesn't match "questions" as an :id.
router.get('/:id/questions', async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid quiz ID' });
        }

        const quiz = await QuizConfig.findOne({
            _id: id,
            ...buildAvailabilityFilter(),
            ...NON_LEGACY_FILTER
        });
        if (!quiz) {
            return res.status(404).json({ message: 'Quiz not found' });
        }

        // Stateless selection: this endpoint is expected to be called once per
        // attempt (quiz start) and the result held client-side until submission.
        // The attempt schema does not store which QuizQuestion IDs were shown,
        // so repeated calls are NOT guaranteed to return the same set/order.
        const pool = await QuizQuestion.find({ quizId: id }).select(QUESTION_FIELDS);

        let selected;
        if (quiz.questionsRandomization) {
            selected = [...pool];
            for (let i = selected.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                [selected[i], selected[j]] = [selected[j], selected[i]];
            }
        } else {
            selected = pool;
        }

        res.json(selected.slice(0, quiz.numberOfQuestions));
    } catch (error) {
        console.error('Error fetching user quiz questions:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/user-quizzes/:id - One available quiz (public)
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid quiz ID' });
        }

        const quiz = await QuizConfig.findOne({
            _id: id,
            ...buildAvailabilityFilter(),
            ...NON_LEGACY_FILTER
        }).select(QUIZ_FIELDS);
        if (!quiz) {
            return res.status(404).json({ message: 'Quiz not found' });
        }

        res.json(quiz);
    } catch (error) {
        console.error('Error fetching user quiz:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/user-quizzes - Currently available quizzes (public)
router.get('/', async (req, res) => {
    try {
        const quizzes = await QuizConfig.find({
            ...buildAvailabilityFilter(),
            ...NON_LEGACY_FILTER
        }).select(QUIZ_FIELDS);
        res.json(quizzes);
    } catch (error) {
        console.error('Error fetching user quizzes:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
