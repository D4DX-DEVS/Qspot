const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const User = require('../models/user');
const Question = require('../models/question');
const Quiz = require('../models/quiz');
const QuizSession = require('../models/quizSession');
const VideoProgress = require('../models/videoProgress');
const VideoQuizAttempt = require('../models/videoQuizAttempt');
const Video = require('../models/videos');
const { authenticateAdmin } = require('../middlewares/auth');
const router = express.Router();

// Admin login route
router.post('/login', async (req, res) => {
    try {
        const { username, password } = req.body || {};

        if (!username || !password) {
            return res.status(400).json({ message: 'Username and password are required' });
        }

        const adminUsername = process.env.ADMIN_USERNAME;
        const adminPassword = process.env.ADMIN_PASSWORD;

        if (!adminUsername || !adminPassword) {
            return res.status(500).json({ message: 'Admin credentials not configured' });
        }

        if (username !== adminUsername) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        // The stored password may be a bcrypt hash or plain text; support both.
        let isPasswordValid = password === adminPassword;
        if (!isPasswordValid) {
            try {
                isPasswordValid = await bcrypt.compare(password, adminPassword);
            } catch (e) {
                isPasswordValid = false;
            }
        }

        if (!isPasswordValid) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        const token = jwt.sign(
            { username: adminUsername, role: 'admin' },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.json({ message: 'Login successful', token });
    } catch (error) {
        console.error('Admin login error:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/admin/users?page&limit&search - paginated user list (admin only)
router.get('/users', authenticateAdmin, async (req, res) => {
    try {
        const page = Math.max(1, parseInt(req.query.page, 10) || 1);
        const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));
        const filter = {};
        if (req.query.search) {
            const re = new RegExp(String(req.query.search).trim(), 'i');
            filter.$or = [{ name: re }, { phone: re }, { email: re }];
        }

        const [items, total] = await Promise.all([
            User.find(filter)
                .sort({ createdAt: -1 })
                .skip((page - 1) * limit)
                .limit(limit),
            User.countDocuments(filter)
        ]);

        res.json({ items, total, page, limit });
    } catch (error) {
        console.error('Error fetching users:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/admin/users/:id - Get single user (admin only)
router.get('/users/:id', authenticateAdmin, async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.json({ message: 'User retrieved successfully', user });
    } catch (error) {
        console.error('Error fetching user:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/admin/users/:id/activity - one user's activity (admin only)
router.get('/users/:id/activity', authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid user id' });
        }

        const user = await User.findById(id);
        if (!user) return res.status(404).json({ message: 'User not found' });

        const [quizAttempts, videoQuizAttempts, progress, questions] = await Promise.all([
            Quiz.find({ userId: id }).populate('quizId', 'title').sort({ createdAt: -1 }),
            VideoQuizAttempt.find({ userId: id }).populate('videoId', 'title').sort({ createdAt: -1 }),
            VideoProgress.find({ userId: id }).populate('videoId', 'title').sort({ lastViewedAt: -1 }),
            Question.find({ user: id }).populate('faculty', 'name').sort({ createdAt: -1 })
        ]);

        res.json({
            user,
            quizAttempts: quizAttempts.map((a) => ({
                attemptId: a._id,
                quizId: a.quizId?._id || a.quizId,
                title: a.quizId?.title || 'Quiz',
                score: a.score,
                totalQuestions: a.totalQuestions,
                percentage: a.percentage,
                createdAt: a.createdAt
            })),
            videoQuizzes: videoQuizAttempts.map((a) => ({
                videoId: a.videoId?._id || a.videoId,
                title: a.videoId?.title || 'Video',
                score: a.score,
                totalQuestions: a.totalQuestions,
                percentage: a.percentage,
                createdAt: a.createdAt
            })),
            progress: progress.map((p) => ({
                videoId: p.videoId?._id || p.videoId,
                title: p.videoId?.title || 'Video',
                status: p.completed ? 'completed' : ((p.watchedSeconds || 0) > 0 ? 'in-progress' : 'not-started'),
                watchedSeconds: p.watchedSeconds,
                durationSeconds: p.durationSeconds,
                completedAt: p.completedAt
            })),
            questions
        });
    } catch (error) {
        console.error('Error fetching user activity:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/admin/users/:id - Update user (admin only)
router.put('/users/:id', authenticateAdmin, async (req, res) => {
    try {
        const { name, phone, email, class: userClass } = req.body || {};

        if (!name || !phone || !userClass) {
            return res.status(400).json({ message: 'Name, phone, and class are required' });
        }

        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        if (phone !== user.phone) {
            const existingUser = await User.findOne({ phone });
            if (existingUser) {
                return res.status(409).json({ message: 'Phone number already exists' });
            }
        }

        const updatedUser = await User.findByIdAndUpdate(
            req.params.id,
            { name, phone, email: email || '', class: userClass },
            { new: true, runValidators: true }
        );

        res.json({ message: 'User updated successfully', user: updatedUser });
    } catch (error) {
        console.error('Error updating user:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/admin/users/:id - Delete user and cascade (admin only)
router.delete('/users/:id', authenticateAdmin, async (req, res) => {
    try {
        const user = await User.findByIdAndDelete(req.params.id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        await Promise.all([
            Question.deleteMany({ user: user._id }),
            Quiz.deleteMany({ userId: user._id }),
            QuizSession.deleteMany({ userId: user._id }),
            VideoProgress.deleteMany({ userId: user._id }),
            VideoQuizAttempt.deleteMany({ userId: user._id })
        ]);

        res.json({ message: 'User deleted successfully', id: user._id });
    } catch (error) {
        console.error('Error deleting user:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/admin/videos/:id/stats - per-video analytics (admin only)
router.get('/videos/:id/stats', authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid video id' });
        }
        const video = await Video.findById(id).select('_id');
        if (!video) return res.status(404).json({ message: 'Video not found' });

        const [progressAgg, quizAgg] = await Promise.all([
            VideoProgress.aggregate([
                { $match: { videoId: video._id } },
                {
                    $group: {
                        _id: null,
                        views: { $sum: 1 },
                        completed: { $sum: { $cond: ['$completed', 1, 0] } },
                        avgWatchedSeconds: { $avg: '$watchedSeconds' }
                    }
                }
            ]),
            VideoQuizAttempt.aggregate([
                { $match: { videoId: video._id } },
                {
                    $group: {
                        _id: null,
                        attempts: { $sum: 1 },
                        avgPercentage: { $avg: '$percentage' }
                    }
                }
            ])
        ]);

        const progressStats = progressAgg[0] || { views: 0, completed: 0, avgWatchedSeconds: 0 };
        const quizStats = quizAgg[0] || { attempts: 0, avgPercentage: 0 };

        res.json({
            videoId: video._id,
            views: progressStats.views || 0,
            completed: progressStats.completed || 0,
            avgWatchedSeconds: Math.round(progressStats.avgWatchedSeconds || 0),
            quiz: {
                attempts: quizStats.attempts || 0,
                avgPercentage: Math.round(quizStats.avgPercentage || 0)
            }
        });
    } catch (error) {
        console.error('Error fetching video stats:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
