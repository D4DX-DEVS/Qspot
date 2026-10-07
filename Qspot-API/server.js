// Suppress AWS SDK v2 deprecation warnings
process.removeAllListeners('warning');
process.on('warning', () => {});

require('dotenv').config();

const dns = require('dns');
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const multer = require('multer');
const path = require('path');

const app = express();

// DigitalOcean App Platform sits in front of the API as a proxy. Trust that one
// hop so req.ip is the real client IP and the OTP rate limit is per user,
// not one shared bucket for everyone.
app.set('trust proxy', 1);

// Windows resolver fails MongoDB SRV lookups; force a resolver that supports them.
dns.setServers(['8.8.8.8', '1.1.1.1']);

app.use(helmet());

const corsOrigin = process.env.CORS_ORIGIN || '*';
app.use(cors({ origin: corsOrigin === '*' ? true : corsOrigin.split(',').map((o) => o.trim()) }));

app.use(express.json());
// Local assignment uploads are served from the same API in development. In
// production the upload middleware stores the same files in object storage.
app.use('/uploads/handouts', (req, res, next) => {
    res.set('Cross-Origin-Resource-Policy', 'cross-origin');
    next();
});
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Express 5 leaves req.body undefined when no JSON body is sent; every
// handler that destructures req.body would otherwise throw a 500 instead of
// returning a proper 400. Normalise it once here.
app.use((req, res, next) => {
    if (!req.body) req.body = {};
    next();
});

// The mobile app is a web build in development, so a heuristically cached
// response would keep showing stale content after the database changes.
// Content is cheap and local here — never let a client cache it.
app.use((req, res, next) => {
    res.set('Cache-Control', 'no-store, no-cache, must-revalidate');
    res.set('Pragma', 'no-cache');
    next();
});

// Rate limit the OTP endpoints: 5 requests/min/IP.
const otpLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: 5,
    standardHeaders: true,
    legacyHeaders: false,
    message: { message: 'Too many requests. Please try again in a minute.' }
});
app.use('/api/user/login/request-otp', otpLimiter);
app.use('/api/user/login/verify', otpLimiter);

// Import routes
const adminRoutes = require('./routes/admin');
const bannerRoutes = require('./routes/banner');
const speakerRoutes = require('./routes/speakers');
const videoRoutes = require('./routes/videos');
const notificationRoutes = require('./routes/notifications');
const questionRoutes = require('./routes/questions');
const quizRoutes = require('./routes/quizzes');
const quizQuestionRoutes = require('./routes/quizQuestions');
const quizDefinitionRoutes = require('./routes/quizDefinitions');
const userQuizRoutes = require('./routes/userQuizzes');
const scheduleRoutes = require('./routes/schedules');
const subjectRoutes = require('./routes/subjects');
const userRoutes = require('./routes/users');
const videoProgressRoutes = require('./routes/videoProgress');
const videoQuestionRoutes = require('./routes/videoQuestions');
const userVideoQuizRoutes = require('./routes/userVideoQuiz');
const courseRoutes = require('./routes/courses');
const assignmentRoutes = require('./routes/assignments');
const learningStatsRoutes = require('./routes/learningStats');
const analyticsRoutes = require('./routes/analytics');
const facultyRoutes = require('./routes/faculty');
const certificateRoutes = require('./routes/certificates');
const { publicRouter: navigationRoutes, adminRouter: adminNavigationRoutes } = require('./routes/navigation');

// Routes. More specific paths are mounted before their less specific parent
// (e.g. /api/user/video-quiz before /api/user) so Express always matches the
// intended router first.
app.use('/api/admin/assignments', assignmentRoutes.adminRouter);
app.use('/api/admin/analytics', analyticsRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/faculty', facultyRoutes);
app.use('/api/banner', bannerRoutes);
app.use('/api/speakers', speakerRoutes);
app.use('/api/videos', videoRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/questions', questionRoutes);
app.use('/api/quizzes', quizRoutes);
app.use('/api/quiz-questions', quizQuestionRoutes);
app.use('/api/quiz-definitions', quizDefinitionRoutes);
app.use('/api/user-quizzes', userQuizRoutes);
app.use('/api/schedules', scheduleRoutes);
app.use('/api/subjects', subjectRoutes);
app.use('/api/user/video-quiz', userVideoQuizRoutes);
app.use('/api/user/assignments', assignmentRoutes.userRouter);
app.use('/api/user/learning-stats', learningStatsRoutes);
app.use('/api/user', userRoutes);
app.use('/api/video-progress', videoProgressRoutes);
app.use('/api/video-questions', videoQuestionRoutes);
app.use('/api/courses', courseRoutes);
app.use('/api/navigation', navigationRoutes);
app.use('/api/admin/navigation', adminNavigationRoutes);
app.use('/api/certificates', certificateRoutes);

// JSON 404 for anything unmatched.
app.use((req, res) => {
    res.status(404).json({ message: 'Not found' });
});

// Global JSON error handler. Must be registered last, with 4 args.
app.use((err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        const status = err.code === 'LIMIT_FILE_SIZE' ? 413 : 400;
        return res.status(status).json({ message: err.message || 'File upload error' });
    }
    if (err && err.status) {
        return res.status(err.status).json({ message: err.message || 'Request failed' });
    }
    if (err && err.type === 'entity.parse.failed') {
        return res.status(400).json({ message: 'Invalid JSON body' });
    }
    console.error('Unhandled error:', err);
    res.status(500).json({ message: 'Internal server error' });
});

const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI, {
            serverSelectionTimeoutMS: 10000,
            socketTimeoutMS: 45000,
        });
        console.log("Connected to MongoDB");
    } catch (error) {
        console.error("MongoDB connection error:", error.message);
        console.log("Retrying connection in 5 seconds...");
        setTimeout(connectDB, 5000);
    }
};

connectDB();

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => {
    console.log(`Server is running on port http://localhost:${PORT}`);
});

module.exports = app;
