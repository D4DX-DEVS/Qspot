const express = require('express');
const Quiz = require('../models/quiz');
const QuizConfig = require('../models/quizConfig');
const { authenticateToken, authenticateUser } = require('../middlewares/auth');

const router = express.Router();

// GET /api/quizzes/config - Get quiz configuration only (public)
router.get('/config', async (req, res) => {
    try {
        const config = await QuizConfig.findOne()
            .select('startDate endDate numberOfQuestions questionsRandomization isEnable createdAt updatedAt')
            .sort({ createdAt: -1 });
        if (!config) {
            return res.status(404).json({ message: 'No quiz configuration found' });
        }
        res.json(config);
    } catch (error) {
        console.error('Error fetching quiz config:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/quizzes/config - Create or update quiz configuration only (admin only)
router.post('/config', authenticateToken, async (req, res) => {
    try {
        const { startDate, endDate, numberOfQuestions, questionsRandomization, isEnable } = req.body;

        if (!startDate || !endDate) {
            return res.status(400).json({ message: 'startDate and endDate are required' });
        }
        if (new Date(startDate) >= new Date(endDate)) {
            return res.status(400).json({ message: 'startDate must be before endDate' });
        }
        if (numberOfQuestions === undefined || numberOfQuestions === null || numberOfQuestions < 1) {
            return res.status(400).json({ message: 'numberOfQuestions must be at least 1' });
        }
        if (questionsRandomization === undefined || questionsRandomization === null) {
            return res.status(400).json({ message: 'questionsRandomization is required' });
        }
        if (isEnable === undefined || isEnable === null) {
            return res.status(400).json({ message: 'isEnable is required' });
        }

        const existingConfig = await QuizConfig.findOne();
        const isUpdate = !!existingConfig;

        const updateData = {
            $set: {
                startDate,
                endDate,
                numberOfQuestions,
                questionsRandomization,
                isEnable
            }
        };

        const config = await QuizConfig.findOneAndUpdate(
            {},
            updateData,
            {
                new: true,
                upsert: true,
                runValidators: true,
                setDefaultsOnInsert: true
            }
        );

        const message = isUpdate
            ? 'Quiz configuration updated successfully'
            : 'Quiz configuration created successfully';

        res.status(isUpdate ? 200 : 201).json({
            message,
            quiz: config
        });
    } catch (error) {
        console.error('Error creating/updating quiz config:', error);
        if (error.message.includes('required') || error.message.includes('Only one quiz configuration')) {
            return res.status(400).json({ message: error.message });
        }
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/quizzes/config - Update quiz configuration only (admin only)
router.put('/config', authenticateToken, async (req, res) => {
    try {
        const { startDate, endDate, numberOfQuestions, questionsRandomization, isEnable } = req.body;

        const existingConfig = await QuizConfig.findOne();

        if (!existingConfig) {
            return res.status(404).json({ message: 'Quiz configuration not found. Use POST to create a new configuration.' });
        }

        const finalStart = startDate !== undefined ? new Date(startDate) : existingConfig.startDate;
        const finalEnd = endDate !== undefined ? new Date(endDate) : existingConfig.endDate;
        const finalNumberOfQuestions = numberOfQuestions !== undefined ? numberOfQuestions : existingConfig.numberOfQuestions;
        const finalQuestionsRandomization = questionsRandomization !== undefined ? questionsRandomization : existingConfig.questionsRandomization;
        const finalIsEnable = isEnable !== undefined ? isEnable : existingConfig.isEnable;

        if (!finalStart || !finalEnd) {
            return res.status(400).json({ message: 'startDate and endDate are required' });
        }
        if (finalStart >= finalEnd) {
            return res.status(400).json({ message: 'startDate must be before endDate' });
        }
        if (finalNumberOfQuestions === undefined || finalNumberOfQuestions === null || finalNumberOfQuestions < 1) {
            return res.status(400).json({ message: 'numberOfQuestions must be at least 1' });
        }
        if (finalQuestionsRandomization === undefined || finalQuestionsRandomization === null) {
            return res.status(400).json({ message: 'questionsRandomization is required' });
        }
        if (finalIsEnable === undefined || finalIsEnable === null) {
            return res.status(400).json({ message: 'isEnable is required' });
        }

        const updateData = {
            $set: {}
        };

        if (startDate !== undefined) {
            updateData.$set.startDate = startDate;
        }
        if (endDate !== undefined) {
            updateData.$set.endDate = endDate;
        }
        if (questionsRandomization !== undefined) {
            updateData.$set.questionsRandomization = questionsRandomization;
        }
        if (numberOfQuestions !== undefined) {
            updateData.$set.numberOfQuestions = numberOfQuestions;
        }
        if (isEnable !== undefined) {
            updateData.$set.isEnable = isEnable;
        }

        const updatedConfig = await QuizConfig.findByIdAndUpdate(
            existingConfig._id,
            updateData,
            { new: true, runValidators: true }
        );

        res.json({
            message: 'Quiz configuration updated successfully',
            quiz: updatedConfig
        });
    } catch (error) {
        console.error('Error updating quiz config:', error);
        if (error.message.includes('required')) {
            return res.status(400).json({ message: error.message });
        }
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/quizzes/config - Delete quiz configuration (admin only)
router.delete('/config', authenticateToken, async (req, res) => {
    try {
        const existingConfig = await QuizConfig.findOne();

        if (!existingConfig) {
            return res.status(404).json({ message: 'Quiz configuration not found' });
        }

        await QuizConfig.findByIdAndDelete(existingConfig._id);

        res.json({
            message: 'Quiz configuration deleted successfully',
            quiz: existingConfig
        });
    } catch (error) {
        console.error('Error deleting quiz config:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/quizzes/attempt - User submits a quiz attempt (within time window)
router.post('/attempt', authenticateUser, async (req, res) => {
    try {
        const { language, questions, answers, score, percentage, totalDuration } = req.body;

        const config = await QuizConfig.findOne();
        if (!config) {
            return res.status(404).json({ message: 'No quiz configuration found' });
        }

        const now = new Date();
        if (!config.isEnable) {
            return res.status(400).json({ message: 'Quiz is currently disabled' });
        }
        if (!(now >= new Date(config.startDate) && now <= new Date(config.endDate))) {
            return res.status(400).json({ message: 'Quiz is not live right now' });
        }

        if (!Array.isArray(questions) || questions.length === 0) {
            return res.status(400).json({ message: 'questions must be a non-empty array' });
        }
        if (questions.length !== config.numberOfQuestions) {
            return res.status(400).json({ message: `questions length (${questions.length}) must equal configured numberOfQuestions (${config.numberOfQuestions})` });
        }
        for (const q of questions) {
            if (
                q.totalNumberOfQuestions === undefined || q.totalNumberOfQuestions === null ||
                !q.questionNumber || !q.question || !Array.isArray(q.options) || q.options.length === 0 ||
                !q.correctAnswer
            ) {
                return res.status(400).json({ message: 'Each question requires totalNumberOfQuestions, questionNumber, question, options[], and correctAnswer' });
            }
            if (Number(q.totalNumberOfQuestions) !== Number(config.numberOfQuestions)) {
                return res.status(400).json({ message: `totalNumberOfQuestions (${q.totalNumberOfQuestions}) must equal configured numberOfQuestions (${config.numberOfQuestions})` });
            }
        }

        if (!Array.isArray(answers) || answers.length === 0) {
            return res.status(400).json({ message: 'answers must be a non-empty array' });
        }
        for (const a of answers) {
            if (a.attemptedAnswer === undefined || a.isCorrect === undefined) {
                return res.status(400).json({ message: 'Each answer requires attemptedAnswer and isCorrect' });
            }
            a.isCorrect = String(a.isCorrect);
            if (a.duration === undefined || a.duration === null) a.duration = 0;
            if (a.language) delete a.language;
        }

        if (language && !["Malayalam", "English"].includes(language)) {
            return res.status(400).json({ message: 'language must be either "Malayalam" or "English"' });
        }

        if (score === undefined || score === null) {
            return res.status(400).json({ message: 'score (total) is required' });
        }
        if (percentage === undefined || percentage === null) {
            return res.status(400).json({ message: 'percentage (total) is required' });
        }
        if (totalDuration === undefined || totalDuration === null) {
            return res.status(400).json({ message: 'totalDuration is required' });
        }

        const existingAttempt = await Quiz.findOne({ userId: req.user.id });
        if (existingAttempt) {
            return res.status(400).json({ message: 'You have already submitted a quiz attempt' });
        }

        const attempt = await Quiz.create({
            userId: req.user.id,
            language,
            questions,
            answers,
            score,
            percentage,
            totalDuration
        });

        return res.status(201).json({
            message: 'Quiz attempt submitted',
            attemptId: attempt._id,
            attempt
        });
    } catch (error) {
        console.error('Error submitting quiz attempt:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/quizzes/attempt/:attemptId - Admin deletes a specific quiz attempt by ID
router.delete('/attempt/:attemptId', authenticateToken, async (req, res) => {
    try {
        const { attemptId } = req.params;

        const attempt = await Quiz.findById(attemptId);
        if (!attempt) {
            return res.status(404).json({ message: 'Quiz attempt not found' });
        }

        await Quiz.findByIdAndDelete(attemptId);

        return res.json({
            message: 'Quiz attempt deleted successfully',
            deletedAttemptId: attemptId
        });
    } catch (error) {
        console.error('Error deleting quiz attempt:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});


// GET /api/quizzes/attempt/:attemptId - Admin: Get full details of a specific quiz attempt
router.get('/attempt/:attemptId', authenticateToken, async (req, res) => {
    try {
        const { attemptId } = req.params;

        const attempt = await Quiz.findById(attemptId)
            .populate({
                path: 'userId',
                select: 'name class email'
            });

        if (!attempt) {
            return res.status(404).json({ message: 'Quiz attempt not found' });
        }

        return res.json({
            attemptId: attempt._id,
            userId: attempt.userId?._id || attempt.userId,
            user: {
                name: attempt.userId?.name || 'Unknown',
                class: attempt.userId?.class || null,
                email: attempt.userId?.email || null
            },
            language: attempt.language || 'English',
            questions: attempt.questions || [],
            answers: attempt.answers || [],
            score: Number(attempt.score) || 0,
            percentage: Number(attempt.percentage) || 0,
            totalDuration: Number(attempt.totalDuration) || 0,
            createdAt: attempt.createdAt,
            updatedAt: attempt.updatedAt
        });
    } catch (error) {
        console.error('Error fetching quiz attempt details:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/quizzes/stats - Admin: result statistics summary
router.get('/stats', authenticateToken, async (req, res) => {
    try {
        const config = await QuizConfig.findOne()
            .sort({ createdAt: -1 });

        const attempts = await Quiz.find()
            .populate({
                path: 'userId',
                select: 'name'
            })
            .sort({ createdAt: -1 });

        const attendees = attempts.map((attempt) => {
            const totalDuration = Number(attempt.totalDuration) || 0;
            const userId = attempt.userId?._id || attempt.userId;
            const userName = attempt.userId?.name || (typeof attempt.userId === 'object' && attempt.userId?.name) || 'Unknown';

            return {
                attemptId: attempt._id,
                userId: userId,
                name: userName,
                score: Number(attempt.score) || 0,
                percentage: Number(attempt.percentage) || 0,
                duration: totalDuration
            };
        });

        const uniqueUserIds = new Set(attendees.map(a => String(a.userId)));

        const response = {
            totalUsersAttended: uniqueUserIds.size,
            attemptsCount: attempts.length,
            attendees
        };

        if (config) {
            response.startDate = config.startDate;
            response.endDate = config.endDate;
            response.numberOfQuestions = config.numberOfQuestions;
            response.questionsRandomization = config.questionsRandomization;
            response.isEnable = config.isEnable;
        }

        return res.json(response);
    } catch (error) {
        console.error('Error fetching quiz stats:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;



