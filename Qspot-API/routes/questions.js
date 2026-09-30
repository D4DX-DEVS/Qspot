const express = require('express');
const mongoose = require('mongoose');
const Question = require('../models/question');
const Speaker = require('../models/speakers');
const { authenticateUser, authenticateAdmin } = require('../middlewares/auth');

const router = express.Router();

// Answers are the point of this Q&A (public FAQ), so they stay visible to any
// signed-in student; only the admin identity behind the answer and hidden
// (moderated) rows are stripped.
const shapeForStudents = (question) => {
    const obj = question.toObject ? question.toObject() : { ...question };
    obj.isAnswered = Boolean(obj.answer);
    delete obj.answeredBy;
    obj.user = obj.user && obj.user.name ? { name: obj.user.name } : { name: 'Anonymous' };
    return obj;
};

// GET /api/questions - list (student only, hides moderated rows)
router.get('/', authenticateUser, async (req, res) => {
    try {
        const questions = await Question.find({
            status: { $ne: 'hidden' },
            $or: [{ class: '' }, { class: null }, { class: req.user.class }]
        })
            .populate('faculty', 'name designation')
            .populate('user', 'name')
            .sort({ createdAt: -1 });

        res.json(questions.map(shapeForStudents));
    } catch (error) {
        console.error('Error fetching questions:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/questions/admin?status=&page&limit - admin listing (includes everything)
router.get('/admin', authenticateAdmin, async (req, res) => {
    try {
        const page = Math.max(1, parseInt(req.query.page, 10) || 1);
        const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));
        const filter = {};
        if (req.query.status) filter.status = req.query.status;

        const [items, total] = await Promise.all([
            Question.find(filter)
                .populate('faculty', 'name designation')
                .populate('user', 'name class')
                .sort({ createdAt: -1 })
                .skip((page - 1) * limit)
                .limit(limit),
            Question.countDocuments(filter)
        ]);

        res.json({ items, total, page, limit });
    } catch (error) {
        console.error('Error fetching admin questions:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/questions/admin/:id - single question with everything (admin)
router.get('/admin/:id', authenticateAdmin, async (req, res) => {
    try {
        const question = await Question.findById(req.params.id)
            .populate('faculty', 'name designation')
            .populate('user', 'name class');

        if (!question) {
            return res.status(404).json({ message: 'Question not found' });
        }

        res.json(question);
    } catch (error) {
        console.error('Error fetching question for admin:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/questions/admin/:id/status - moderate (open/hidden) (admin only)
router.put('/admin/:id/status', authenticateAdmin, async (req, res) => {
    try {
        const { status } = req.body || {};
        if (!['open', 'hidden'].includes(status)) {
            return res.status(400).json({ message: "status must be 'open' or 'hidden'" });
        }

        const question = await Question.findByIdAndUpdate(
            req.params.id,
            { status },
            { new: true, runValidators: true }
        ).populate('faculty', 'name designation').populate('user', 'name class');

        if (!question) {
            return res.status(404).json({ message: 'Question not found' });
        }

        res.json({ message: 'Question status updated', question });
    } catch (error) {
        console.error('Error updating question status:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/questions/admin/:id - admin delete (moderation)
router.delete('/admin/:id', authenticateAdmin, async (req, res) => {
    try {
        const question = await Question.findByIdAndDelete(req.params.id);
        if (!question) {
            return res.status(404).json({ message: 'Question not found' });
        }
        res.json({ message: 'Question deleted successfully', id: question._id });
    } catch (error) {
        console.error('Error deleting question (admin):', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/questions/:id - single question (student only, hides moderated rows)
router.get('/:id', authenticateUser, async (req, res) => {
    try {
        const question = await Question.findOne({
            _id: req.params.id,
            status: { $ne: 'hidden' },
            $or: [{ class: '' }, { class: null }, { class: req.user.class }]
        })
            .populate('faculty', 'name designation')
            .populate('user', 'name');

        if (!question) {
            return res.status(404).json({ message: 'Question not found' });
        }

        res.json(shapeForStudents(question));
    } catch (error) {
        console.error('Error fetching question:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/questions - Create new question (user only)
router.post('/', authenticateUser, async (req, res) => {
    try {
        const { description, faculty, subject } = req.body || {};

        if (!description || !faculty || !subject) {
            return res.status(400).json({ message: 'Description, faculty, and subject are required' });
        }

        const existingFaculty = await Speaker.findById(faculty);
        if (!existingFaculty) {
            return res.status(404).json({ message: 'Faculty not found' });
        }

        const question = new Question({
            description,
            faculty,
            subject,
            user: req.user.id,
            class: req.user.class || ''
        });

        const savedQuestion = await question.save();
        const populatedQuestion = await Question.findById(savedQuestion._id)
            .populate('faculty', 'name designation');

        res.status(201).json({
            message: 'Question created successfully',
            question: populatedQuestion
        });
    } catch (error) {
        console.error('Error creating question:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/questions/:id - Update question (owner only)
router.put('/:id', authenticateUser, async (req, res) => {
    try {
        const { description, faculty, subject } = req.body || {};
        const oldQuestion = await Question.findById(req.params.id);

        if (!oldQuestion) {
            return res.status(404).json({ message: 'Question not found' });
        }

        if (!oldQuestion.user || oldQuestion.user.toString() !== req.user.id) {
            return res.status(403).json({ message: 'You can only update your own questions' });
        }

        if (!description || !faculty || !subject) {
            return res.status(400).json({ message: 'Description, faculty, and subject are required' });
        }

        const existingFaculty = await Speaker.findById(faculty);
        if (!existingFaculty) {
            return res.status(404).json({ message: 'Faculty not found' });
        }

        const question = await Question.findByIdAndUpdate(
            req.params.id,
            { description, faculty, subject },
            { new: true, runValidators: true }
        ).populate('faculty', 'name designation');

        res.json({ message: 'Question updated successfully', question });
    } catch (error) {
        console.error('Error updating question:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/questions/:id - Delete question (owner only)
router.delete('/:id', authenticateUser, async (req, res) => {
    try {
        const question = await Question.findById(req.params.id);

        if (!question) {
            return res.status(404).json({ message: 'Question not found' });
        }

        if (!question.user || question.user.toString() !== req.user.id) {
            return res.status(403).json({ message: 'You can only delete your own questions' });
        }

        await Question.findByIdAndDelete(req.params.id);

        res.json({ message: 'Question deleted successfully', id: question._id });
    } catch (error) {
        console.error('Error deleting question:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/questions/:id/answer - Admin answers a question
router.post('/:id/answer', authenticateAdmin, async (req, res) => {
    try {
        const { answer } = req.body || {};
        const questionId = req.params.id;

        if (!answer || answer.trim() === '') {
            return res.status(400).json({ message: 'Answer is required' });
        }

        const question = await Question.findById(questionId);
        if (!question) {
            return res.status(404).json({ message: 'Question not found' });
        }

        if (question.answer) {
            return res.status(400).json({ message: 'Question already has an answer' });
        }

        const updatedQuestion = await Question.findByIdAndUpdate(
            questionId,
            {
                answer: answer.trim(),
                answeredBy: req.user.username,
                answeredAt: new Date()
            },
            { new: true, runValidators: true }
        ).populate('faculty', 'name designation')
         .populate('user', 'name class');

        res.json({ message: 'Answer added successfully', question: updatedQuestion });
    } catch (error) {
        console.error('Error adding answer:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/questions/:id/answer - Admin updates answer
router.put('/:id/answer', authenticateAdmin, async (req, res) => {
    try {
        const { answer } = req.body || {};
        const questionId = req.params.id;

        if (!answer || answer.trim() === '') {
            return res.status(400).json({ message: 'Answer is required' });
        }

        const question = await Question.findById(questionId);
        if (!question) {
            return res.status(404).json({ message: 'Question not found' });
        }

        if (!question.answer) {
            return res.status(400).json({ message: 'Question has no answer to update' });
        }

        const updatedQuestion = await Question.findByIdAndUpdate(
            questionId,
            {
                answer: answer.trim(),
                answeredBy: req.user.username,
                answeredAt: new Date()
            },
            { new: true, runValidators: true }
        ).populate('faculty', 'name designation')
         .populate('user', 'name class');

        res.json({ message: 'Answer updated successfully', question: updatedQuestion });
    } catch (error) {
        console.error('Error updating answer:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/questions/:id/answer - Admin deletes answer
router.delete('/:id/answer', authenticateAdmin, async (req, res) => {
    try {
        const questionId = req.params.id;

        const question = await Question.findById(questionId);
        if (!question) {
            return res.status(404).json({ message: 'Question not found' });
        }

        if (!question.answer) {
            return res.status(400).json({ message: 'Question has no answer to delete' });
        }

        const updatedQuestion = await Question.findByIdAndUpdate(
            questionId,
            { answer: null, answeredBy: null, answeredAt: null },
            { new: true, runValidators: true }
        ).populate('faculty', 'name designation')
         .populate('user', 'name class');

        res.json({ message: 'Answer deleted successfully', question: updatedQuestion });
    } catch (error) {
        console.error('Error deleting answer:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
