// Notifications that depend on the clock: announcements whose send time has
// come, quizzes that opened or close soon, assignments due soon, and lessons
// released on a date. Run every few minutes by startNotificationJobs; each
// event reaches a learner once (see services/notify.js).
const Notification = require('../models/notification');
const QuizConfig = require('../models/quizConfig');
const Quiz = require('../models/quiz');
const Assignment = require('../models/assignment');
const AssignmentSubmission = require('../models/assignmentSubmission');
const Video = require('../models/videos');
const { deliver, learnerIds } = require('./notify');
const { reportError } = require('./errorReporter');

const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;
// Older announcements saved before scheduling existed are not sent again.
const LEGACY_WINDOW = 14 * DAY;

const without = (ids, excluded) => {
    const skip = new Set(excluded.map(String));
    return ids.filter((id) => !skip.has(String(id)));
};

// Learners a quiz is meant for who have not sent answers yet.
const quizLearners = async (quiz) => {
    const classes = Array.isArray(quiz.allowedClasses) ? quiz.allowedClasses : [];
    const [ids, attempted] = await Promise.all([
        learnerIds({ classes: classes.length ? classes : null }),
        Quiz.find({ quizId: quiz._id }).distinct('userId')
    ]);
    return without(ids, attempted);
};

const announcements = async (now) => {
    // Too old to send now: mark as handled without sending.
    await Notification.updateMany(
        { dispatchedAt: null, sendAt: null, createdAt: { $lt: new Date(now - LEGACY_WINDOW) } },
        { $set: { dispatchedAt: now } }
    );
    const due = await Notification.find({
        dispatchedAt: null,
        $or: [{ sendAt: { $lte: now } }, { sendAt: null }]
    }).select('_id').lean();
    let sent = 0;
    for (const { _id } of due) {
        // Claimed by one server only.
        const item = await Notification.findOneAndUpdate({ _id, dispatchedAt: null }, { $set: { dispatchedAt: now } }, { new: true }).lean();
        if (!item) continue;
        const audience = item.audience || { kind: 'all' };
        const ids = await learnerIds({
            classes: audience.kind === 'class' && audience.value ? [audience.value] : null,
            courseId: audience.kind === 'course' && audience.value ? audience.value : null
        });
        const count = await deliver(ids, {
            kind: 'announcement',
            title: item.title,
            body: item.description,
            target: item.target?.kind && item.target.kind !== 'none' ? item.target : { kind: 'none', id: '' },
            sourceKey: `announcement:${item._id}`
        });
        await Notification.updateOne({ _id }, { $set: { recipientCount: count } });
        sent += count;
    }
    return sent;
};

const quizOpen = async (now) => {
    const quizzes = await QuizConfig.find({
        isEnable: true,
        startDate: { $gt: new Date(now - DAY), $lte: now },
        endDate: { $gt: now }
    }).select('title allowedClasses').lean();
    let sent = 0;
    for (const quiz of quizzes) {
        sent += await deliver(await quizLearners(quiz), {
            kind: 'quiz_open',
            title: `Quiz open: ${quiz.title}`,
            body: 'It is live now. Open it from Quizzes and Exams.',
            target: { kind: 'quiz', id: String(quiz._id) },
            sourceKey: `quiz_open:${quiz._id}`
        });
    }
    return sent;
};

const quizClosing = async (now) => {
    const quizzes = await QuizConfig.find({
        isEnable: true,
        startDate: { $lte: now },
        endDate: { $gt: now, $lte: new Date(now.getTime() + HOUR) }
    }).select('title allowedClasses').lean();
    let sent = 0;
    for (const quiz of quizzes) {
        sent += await deliver(await quizLearners(quiz), {
            kind: 'quiz_closing',
            title: `${quiz.title} closes soon`,
            body: "It closes within the hour, and you haven't sent your answers yet.",
            target: { kind: 'quiz', id: String(quiz._id) },
            sourceKey: `quiz_closing:${quiz._id}`
        });
    }
    return sent;
};

const assignmentDue = async (now) => {
    const assignments = await Assignment.find({
        isPublished: true,
        dueAt: { $gt: now, $lte: new Date(now.getTime() + DAY) },
        $or: [{ releaseAt: null }, { releaseAt: { $lte: now } }]
    }).select('title class').lean();
    let sent = 0;
    for (const assignment of assignments) {
        const [ids, submitted] = await Promise.all([
            learnerIds({ classes: assignment.class ? [assignment.class] : null }),
            AssignmentSubmission.find({ assignmentId: assignment._id, status: { $ne: 'returned' } }).distinct('userId')
        ]);
        sent += await deliver(without(ids, submitted), {
            kind: 'assignment_due',
            title: `${assignment.title} is due soon`,
            body: 'It is due within a day.',
            target: { kind: 'assignment', id: String(assignment._id) },
            sourceKey: `assignment_due:${assignment._id}`
        });
    }
    return sent;
};

// Lessons with a release date that passed in the last day. Lessons published
// without a date are not announced.
const lessonReleased = async (now) => {
    const videos = await Video.find({ isPublished: { $ne: false }, releaseDate: { $nin: [null, ''] } }).select('title releaseDate').lean();
    const released = videos.filter((video) => {
        const at = new Date(video.releaseDate);
        return !Number.isNaN(at.getTime()) && at <= now && at > new Date(now - DAY);
    });
    if (!released.length) return 0;
    const ids = await learnerIds();
    let sent = 0;
    for (const video of released) {
        sent += await deliver(ids, {
            kind: 'lesson_released',
            title: `New lesson: ${video.title}`,
            body: 'It is open now.',
            target: { kind: 'lesson', id: String(video._id) },
            sourceKey: `lesson_released:${video._id}`
        });
    }
    return sent;
};

const jobs = { announcements, quizOpen, quizClosing, assignmentDue, lessonReleased };

// Runs every job once; one failing job does not stop the others.
const runNotificationJobs = async (now = new Date()) => {
    const results = {};
    for (const [name, job] of Object.entries(jobs)) {
        try {
            results[name] = await job(now);
        } catch (error) {
            reportError(error, { label: `Notification job ${name} failed:` });
            results[name] = null;
        }
    }
    return results;
};

// Every NOTIFICATION_JOBS_SECONDS (default 300; 0 turns them off).
const startNotificationJobs = (env = process.env) => {
    const seconds = Number(env.NOTIFICATION_JOBS_SECONDS ?? 300);
    if (!Number.isFinite(seconds) || seconds <= 0) return null;
    let running = false;
    const tick = async () => {
        if (running) return;
        running = true;
        try {
            await runNotificationJobs(new Date());
        } finally {
            running = false;
        }
    };
    const timer = setInterval(tick, seconds * 1000);
    timer.unref();
    setTimeout(tick, 30 * 1000).unref();
    return timer;
};

module.exports = { runNotificationJobs, startNotificationJobs, jobs };
