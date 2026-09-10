const express = require('express');
const Question = require('../models/question');
const Speaker = require('../models/speakers');
const { authenticateUser, authenticateToken } = require('../middlewares/auth');

const router = express.Router();

// GET /api/questions - Get all questions (public)
router.get('/', async (req, res) => {
    try {
        const questions = await Question.find()
            .populate('faculty', 'name designation')
            .populate('user', 'name class')
            .sort({ createdAt: -1 });

        // Remove answer details for public access (only show if answered)
        const publicQuestions = questions.map(question => {
            const questionObj = question.toObject();
            if (questionObj.answer) {
                // Only show that it's answered, not the actual answer
                questionObj.isAnswered = true;
                delete questionObj.answer;
                delete questionObj.answeredBy;
                delete questionObj.answeredAt;
            } else {
                questionObj.isAnswered = false;
            }
            
            // Handle cases where user field might be missing (legacy data)
            if (!questionObj.user) {
                questionObj.user = {
                    name: 'Anonymous',
                    class: 'Unknown'
                };
            }
            
            return questionObj;
        });

        res.json(publicQuestions);
    } catch (error) {
        console.error('Error fetching questions:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/questions/admin/:id - Get single question with answer for admin
router.get('/admin/:id', authenticateToken, async (req, res) => {
    try {
        const question = await Question.findById(req.params.id)
            .populate('faculty', 'name designation')
            .populate('user', 'name class');

        if (!question) {
            return res.status(404).json({ message: 'Question not found' });
        }

        const questionObj = question.toObject();
        questionObj.isAnswered = Boolean(questionObj.answer);

        if (!questionObj.user) {
            questionObj.user = {
                name: 'Anonymous',
                class: 'Unknown'
            };
        }

        res.json(questionObj);
    } catch (error) {
        console.error('Error fetching question for admin:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});


// GET /api/questions/:id - Get single question (public)
router.get('/:id', async (req, res) => {
    try {
        const question = await Question.findById(req.params.id)
            .populate('faculty', 'name designation')
            .populate('user', 'name class');
        
        if (!question) {
            return res.status(404).json({ message: 'Question not found' });
        }

        // Remove answer details for public access (only show if answered)
        const questionObj = question.toObject();
        if (questionObj.answer) {
            // Only show that it's answered, not the actual answer
            questionObj.isAnswered = true;
            delete questionObj.answer;
            delete questionObj.answeredBy;
            delete questionObj.answeredAt;
        } else {
            questionObj.isAnswered = false;
        }
        
        // Handle cases where user field might be missing (legacy data)
        if (!questionObj.user) {
            questionObj.user = {
                name: 'Anonymous',
                class: 'Unknown'
            };
        }

        res.json(questionObj);
    } catch (error) {
        console.error('Error fetching question:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/questions - Create new question (user only)
router.post('/', authenticateUser, async (req, res) => {
    try {
        const { description, faculty, subject } = req.body;

        if (!description || !faculty || !subject) {
            return res.status(400).json({ message: 'Description, faculty, and subject are required' });
        }

        // Check if faculty exists
        const existingFaculty = await Speaker.findById(faculty);
        if (!existingFaculty) {
            return res.status(404).json({ message: 'Faculty not found' });
        }

        // Subject is now a string, no need to validate existence

        const question = new Question({
            description,
            faculty,
            subject,
            user: req.user.id
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

// PUT /api/questions/:id - Update question (user only)
router.put('/:id', authenticateUser, async (req, res) => {
    try {
        const { description, faculty, subject } = req.body;
        const oldQuestion = await Question.findById(req.params.id);

        if (!oldQuestion) {
            return res.status(404).json({ message: 'Question not found' });
        }

        // Check if the question belongs to the authenticated user
        if (!oldQuestion.user || oldQuestion.user.toString() !== req.user.id) {
            return res.status(403).json({ message: 'You can only update your own questions' });
        }

        if (!description || !faculty || !subject) {
            return res.status(400).json({ message: 'Description, faculty, and subject are required' });
        }

        // Check if faculty exists
        const existingFaculty = await Speaker.findById(faculty);
        if (!existingFaculty) {
            return res.status(404).json({ message: 'Faculty not found' });
        }

        // Subject is now a string, no need to validate existence

        const question = await Question.findByIdAndUpdate(
            req.params.id,
            { description, faculty, subject },
            { new: true, runValidators: true }
        ).populate('faculty', 'name designation');

        res.json({
            message: 'Question updated successfully',
            question
        });
    } catch (error) {
        console.error('Error updating question:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/questions/:id - Delete question (user only)
router.delete('/:id', authenticateUser, async (req, res) => {
    try {
        const question = await Question.findById(req.params.id);

        if (!question) {
            return res.status(404).json({ message: 'Question not found' });
        }

        // Check if the question belongs to the authenticated user
        if (!question.user || question.user.toString() !== req.user.id) {
            return res.status(403).json({ message: 'You can only delete your own questions' });
        }

        await Question.findByIdAndDelete(req.params.id);

        res.json({
            message: 'Question deleted successfully',
            question
        });
    } catch (error) {
        console.error('Error deleting question:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/questions/:id/answer - Admin answers a question
router.post('/:id/answer', authenticateToken, async (req, res) => {
    try {
        const { answer } = req.body;
        const questionId = req.params.id;

        if (!answer || answer.trim() === '') {
            return res.status(400).json({ message: 'Answer is required' });
        }

        const question = await Question.findById(questionId);
        if (!question) {
            return res.status(404).json({ message: 'Question not found' });
        }

        // Check if question already has an answer
        if (question.answer) {
            return res.status(400).json({ message: 'Question already has an answer' });
        }

        // Update question with answer
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

        res.json({
            message: 'Answer added successfully',
            question: updatedQuestion
        });
    } catch (error) {
        console.error('Error adding answer:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/questions/:id/answer - Admin updates answer
router.put('/:id/answer', authenticateToken, async (req, res) => {
    try {
        const { answer } = req.body;
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

        // Update answer
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

        res.json({
            message: 'Answer updated successfully',
            question: updatedQuestion
        });
    } catch (error) {
        console.error('Error updating answer:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/questions/:id/answer - Admin deletes answer
router.delete('/:id/answer', authenticateToken, async (req, res) => {
    try {
        const questionId = req.params.id;

        const question = await Question.findById(questionId);
        if (!question) {
            return res.status(404).json({ message: 'Question not found' });
        }

        if (!question.answer) {
            return res.status(400).json({ message: 'Question has no answer to delete' });
        }

        // Remove answer
        const updatedQuestion = await Question.findByIdAndUpdate(
            questionId,
            {
                answer: null,
                answeredBy: null,
                answeredAt: null
            },
            { new: true, runValidators: true }
        ).populate('faculty', 'name designation')
         .populate('user', 'name class');

        res.json({
            message: 'Answer deleted successfully',
            question: updatedQuestion
        });
    } catch (error) {
        console.error('Error deleting answer:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
