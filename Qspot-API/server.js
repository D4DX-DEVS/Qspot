// The AWS SDK v2 (used by the upload middleware) prints a "maintenance mode"
// note at start-up. Switch off only that note; every other Node warning
// (deprecations, possible memory leaks) stays visible in the logs.
process.env.AWS_SDK_JS_SUPPRESS_MAINTENANCE_MODE_MESSAGE ??= '1';

require('dotenv').config();

const dns = require('dns');
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { loginIpLimiter, loginPhoneLimiter, adminLoginLimiter } = require('./middlewares/loginLimiter');
const multer = require('multer');
const path = require('path');
const { reportError } = require('./services/errorReporter');
const { startNotificationJobs } = require('./services/notificationJobs');

const app = express();

// DigitalOcean App Platform sits in front of the API as a proxy. Trust that one
// hop so req.ip is the real client IP and the OTP rate limit is per user,
// not one shared bucket for everyone.
app.set('trust proxy', 1);

// Logged once per start, on the first request that came through a proxy:
// shows the address login limits are counted against. If it is a proxy's
// address rather than the student's (first in x-forwarded-for), there are
// more proxy hops than 'trust proxy' above allows for, and every student
// shares one limit.
let proxyChecked = false;
app.use((req, res, next) => {
    const forwarded = req.headers['x-forwarded-for'];
    if (!proxyChecked && forwarded) {
        proxyChecked = true;
        const client = String(forwarded).split(',')[0].trim();
        console.log(`Proxy check: limits count per ${req.ip}; x-forwarded-for "${forwarded}"; `
            + (req.ip === client ? 'matches the client, setting is right' : 'NOT the client, check trust proxy'));
    }
    next();
});

// Windows resolver fails MongoDB SRV lookups; force a resolver that supports them.
dns.setServers(['8.8.8.8', '1.1.1.1']);

app.use(helmet());

// Load balancer / uptime probe. 503 until MongoDB is connected, so traffic is
// not routed to an instance that cannot answer yet.
app.get('/healthz', (req, res) => {
    const ready = mongoose.connection.readyState === 1;
    res.status(ready ? 200 : 503).json({ status: ready ? 'ok' : 'database-unavailable' });
});

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

// Sign-in with phone number + date of birth: limit failed guesses.
app.post('/api/user/login', loginIpLimiter(), loginPhoneLimiter());
// Admin sign-in: 5 wrong passwords per device in 15 minutes.
app.post('/api/admin/login', adminLoginLimiter());

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
app.use('/api/admin/gradebook', require('./routes/gradebook'));
app.use('/api/user/notifications', require('./routes/userNotifications'));
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
    reportError(err, { label: 'Unhandled error:', method: req.method, path: req.path });
    res.status(500).json({ message: 'Internal server error' });
});

const intFromEnv = (name, fallback) => {
    const value = Number.parseInt(process.env[name], 10);
    return Number.isFinite(value) && value >= 0 ? value : fallback;
};

// Connection pool, sized for a class of students opening and submitting a quiz
// in the same minute. Each instance may open up to MONGO_MAX_POOL_SIZE
// connections, so (instances x max pool) must stay under the database tier's
// connection limit.
//  - minPoolSize keeps connections warm: a cold pool opens them all at once,
//    each with a TLS handshake, exactly when the burst arrives.
//  - waitQueueTimeoutMS fails a request that cannot get a connection in time
//    (the app retries) instead of letting it hang and pile up behind others.
const poolOptions = {
    maxPoolSize: intFromEnv('MONGO_MAX_POOL_SIZE', 100),
    minPoolSize: intFromEnv('MONGO_MIN_POOL_SIZE', 10),
    maxIdleTimeMS: 60 * 1000,
    // Renamed in a future MongoDB driver (use timeoutMS, which limits the
    // whole operation, not just the wait for a connection). Revisit when
    // upgrading mongoose; it works as-is with driver 6.x.
    waitQueueTimeoutMS: intFromEnv('MONGO_WAIT_QUEUE_TIMEOUT_MS', 10000)
};

const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI, {
            serverSelectionTimeoutMS: 10000,
            socketTimeoutMS: 45000,
            ...poolOptions
        });
        console.log("Connected to MongoDB");
        // Scheduled notifications (quiz closing soon, assignment due, ...).
        startNotificationJobs();
    } catch (error) {
        console.error("MongoDB connection error:", error.message);
        console.log("Retrying connection in 5 seconds...");
        setTimeout(connectDB, 5000);
    }
};

connectDB();

const PORT = process.env.PORT || 5001;
const server = app.listen(PORT, () => {
    console.log(`Server is running on port http://localhost:${PORT}`);
});

// Node closes idle keep-alive connections after 5 s by default, shorter than the
// idle timeout of the proxy in front (about 60 s). The proxy then reuses a
// connection Node just closed and the user sees a random 502 under load.
server.keepAliveTimeout = 65 * 1000;
server.headersTimeout = 66 * 1000;

// A deploy or scale-down sends SIGTERM. Stop taking new requests but let the
// ones in flight (a student's submission) finish before the process exits.
const shutdown = (signal) => {
    console.log(`${signal} received, finishing in-flight requests...`);
    server.close(async () => {
        await mongoose.disconnect();
        process.exit(0);
    });
    server.closeIdleConnections?.();
    setTimeout(() => process.exit(1), 15000).unref();
};
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

// An error nothing caught still stops the process, as Node does by default
// (the platform restarts it), but is reported first.
const reportAndExit = (label) => (error) => {
    reportError(error, { label });
    setTimeout(() => process.exit(1), 500).unref();
};
process.on('uncaughtException', reportAndExit('Uncaught exception:'));
process.on('unhandledRejection', reportAndExit('Unhandled promise rejection:'));

module.exports = app;
