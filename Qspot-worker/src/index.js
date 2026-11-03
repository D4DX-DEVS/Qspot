import express from './shims/express.js';
import mongoose from './shims/mongoose.js';
import bindings from './shims/bindings.js';
import rateLimit from 'express-rate-limit';
import loginLimiters from './app/middlewares/loginLimiter.js';
import errorReporter from './app/services/errorReporter.js';
import notificationJobs from './app/services/notificationJobs.js';

import adminRoutes from './app/routes/admin.js';
import bannerRoutes from './app/routes/banner.js';
import speakerRoutes from './app/routes/speakers.js';
import videoRoutes from './app/routes/videos.js';
import notificationRoutes from './app/routes/notifications.js';
import questionRoutes from './app/routes/questions.js';
import quizRoutes from './app/routes/quizzes.js';
import quizQuestionRoutes from './app/routes/quizQuestions.js';
import quizDefinitionRoutes from './app/routes/quizDefinitions.js';
import userQuizRoutes from './app/routes/userQuizzes.js';
import scheduleRoutes from './app/routes/schedules.js';
import subjectRoutes from './app/routes/subjects.js';
import userRoutes from './app/routes/users.js';
import videoProgressRoutes from './app/routes/videoProgress.js';
import videoQuestionRoutes from './app/routes/videoQuestions.js';
import userVideoQuizRoutes from './app/routes/userVideoQuiz.js';
import courseRoutes from './app/routes/courses.js';
import assignmentRoutes from './app/routes/assignments.js';
import learningStatsRoutes from './app/routes/learningStats.js';
import analyticsRoutes from './app/routes/analytics.js';
import facultyRoutes from './app/routes/faculty.js';
import certificateRoutes from './app/routes/certificates.js';
import gradebookRoutes from './app/routes/gradebook.js';
import userNotificationRoutes from './app/routes/userNotifications.js';
import navigation from './app/routes/navigation.js';

const { loginIpLimiter, loginPhoneLimiter, adminLoginLimiter } = loginLimiters;
const { reportError } = errorReporter;
const { runNotificationJobs } = notificationJobs;

const app = express.Router();

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

// More specific paths are mounted before their less specific parent.
app.use('/api/admin/assignments', assignmentRoutes.adminRouter);
app.use('/api/admin/analytics', analyticsRoutes);
app.use('/api/admin/gradebook', gradebookRoutes);
app.use('/api/user/notifications', userNotificationRoutes);
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
app.use('/api/navigation', navigation.publicRouter);
app.use('/api/admin/navigation', navigation.adminRouter);
app.use('/api/certificates', certificateRoutes);

const onError = (err, req, res) => {
    if (err && err.name === 'MulterError') {
        return res.status(err.code === 'LIMIT_FILE_SIZE' ? 413 : 400).json({ message: err.message || 'File upload error' });
    }
    if (err && err.status) return res.status(err.status).json({ message: err.message || 'Request failed' });
    reportError(err, { label: 'Unhandled error:', method: req.method, path: req.path });
    return res.status(500).json({ message: 'Internal server error' });
};

const corsHeaders = (request, env) => {
    const allowed = (env.CORS_ORIGIN || '*').split(',').map((o) => o.trim());
    const origin = request.headers.get('origin');
    const h = {
        'Access-Control-Allow-Methods': 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
        'Access-Control-Allow-Headers': request.headers.get('access-control-request-headers') || 'Content-Type, Authorization',
        'Access-Control-Max-Age': '86400',
        Vary: 'Origin'
    };
    if (allowed.includes('*')) h['Access-Control-Allow-Origin'] = origin || '*';
    else if (origin && allowed.includes(origin)) h['Access-Control-Allow-Origin'] = origin;
    return h;
};

const withHeaders = (response, request, env, extra = {}) => {
    const res = new Response(response.body, response);
    const headers = {
        ...corsHeaders(request, env),
        'X-Content-Type-Options': 'nosniff',
        'Referrer-Policy': 'no-referrer',
        'Cross-Origin-Resource-Policy': 'cross-origin',
        ...extra
    };
    for (const [k, v] of Object.entries(headers)) res.headers.set(k, v);
    return res;
};

const bind = (env) => {
    bindings.set(env);
    mongoose.__setDb(env.DB);
};

export default {
    async fetch(request, env) {
        bind(env);
        const url = new URL(request.url);
        if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsHeaders(request, env) });

        if (url.pathname === '/healthz') {
            let ok = true;
            try { await env.DB.prepare('SELECT 1').first(); } catch { ok = false; }
            return withHeaders(Response.json({ status: ok ? 'ok' : 'database-unavailable' }, { status: ok ? 200 : 503 }), request, env);
        }

        // Files uploaded to R2 (used when R2_PUBLIC_URL is not set).
        if (url.pathname.startsWith('/files/') && (request.method === 'GET' || request.method === 'HEAD')) {
            const key = decodeURIComponent(url.pathname.slice('/files/'.length));
            const range = request.headers.get('range');
            const obj = await env.BUCKET.get(key, range ? { range: request.headers } : undefined);
            if (!obj) return withHeaders(Response.json({ message: 'Not found' }, { status: 404 }), request, env);
            const headers = new Headers();
            obj.writeHttpMetadata(headers);
            headers.set('etag', obj.httpEtag);
            headers.set('cache-control', 'public, max-age=31536000, immutable');
            headers.set('accept-ranges', 'bytes');
            return withHeaders(new Response(request.method === 'HEAD' ? null : obj.body, { status: range && obj.range ? 206 : 200, headers }), request, env);
        }

        const response = await express.dispatch(app, request, { onError });
        return withHeaders(response, request, env, { 'Cache-Control': 'no-store, no-cache, must-revalidate', Pragma: 'no-cache' });
    },

    // Cron trigger (see wrangler.toml): scheduled notifications.
    async scheduled(event, env, ctx) {
        bind(env);
        ctx.waitUntil(runNotificationJobs(new Date()));
    }
};
