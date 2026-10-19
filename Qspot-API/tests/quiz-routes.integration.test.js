// End-to-end checks of the quiz and sign-in routes against a real server and
// database. Runs only when TEST_MONGODB_URI points at a LOCAL database whose
// name contains "test" (it creates and deletes its own records):
//
//   TEST_MONGODB_URI=mongodb://127.0.0.1:27017/qspot_test node --test tests/
const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { spawn } = require('node:child_process');

const URI = process.env.TEST_MONGODB_URI || '';
const LOCAL_TEST_DB = /^mongodb:\/\/(127\.0\.0\.1|localhost)(:\d+)?\/[^?]*test/i.test(URI);
const skip = LOCAL_TEST_DB ? false : 'set TEST_MONGODB_URI to a local *test* database to run';

const SECRET = 'integration-secret';
const PORT = 5098;
const BASE = `http://127.0.0.1:${PORT}`;
const MINUTE = 60 * 1000;

let server;
let models;
let jwt;
const created = { users: [], quizzes: [], videos: [], assignments: [], notifications: [] };

const call = async (route, token, body) => {
    const res = await fetch(BASE + route, {
        method: body ? 'POST' : 'GET',
        headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
        body: body ? JSON.stringify(body) : undefined
    });
    return { status: res.status, body: await res.json().catch(() => null) };
};

const put = async (route, token, body) => {
    const res = await fetch(BASE + route, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify(body)
    });
    return { status: res.status, body: await res.json().catch(() => null) };
};

const student = async (overrides = {}) => {
    const user = await models.User.create({ name: 'Integration', phone: `it-${Date.now()}-${Math.random()}`, class: '8', ...overrides });
    created.users.push(user._id);
    return { user, token: jwt.sign({ userId: user._id.toString(), phone: user.phone, role: 'student' }, SECRET) };
};

const quiz = async ({ questions = 2, ...fields } = {}) => {
    const config = await models.QuizConfig.create({
        title: 'Integration Quiz',
        startDate: new Date(Date.now() - 60 * MINUTE),
        endDate: new Date(Date.now() + 60 * MINUTE),
        numberOfQuestions: questions,
        isEnable: true,
        ...fields
    });
    created.quizzes.push(config._id);
    const items = await models.QuizQuestion.insertMany(Array.from({ length: questions }, (_, i) => ({
        quizId: config._id, type: 'Multiple Choice', question_en: `Q${i}`, question_ml: `Q${i}`,
        options_en: '["A","B","C"]', options_ml: '["A","B","C"]', correct_answer: 'A', difficulty: 'easy'
    })));
    return { config, items };
};

const answers = (questions, pick = 0, duration = 5) =>
    questions.map((q) => ({ questionId: q._id, attemptedAnswer: pick, duration }));

// A watched lesson with two practice questions whose right answer is option 0.
const practiceLesson = async (userId, fields = {}) => {
    const mongoose = require('mongoose');
    const video = await models.Video.create({
        title: 'Integration Lesson', video: 'https://example.com/v.mp4', subject: new mongoose.Types.ObjectId(),
        practiceEnabled: true, practiceEndDate: new Date(Date.now() + 60 * MINUTE), ...fields
    });
    created.videos.push(video._id);
    const items = await models.VideoQuestion.insertMany(Array.from({ length: 2 }, (_, i) => ({
        videoId: video._id, type: 'Multiple Choice', question_en: `P${i}`, question_ml: `P${i}`,
        options_en: '["A","B","C"]', options_ml: '["A","B","C"]', correct_answer: 'A', difficulty: 'easy'
    })));
    await models.VideoProgress.create({ userId, videoId: video._id, completed: true, completedAt: new Date() });
    return { video, items };
};

const practiceAnswers = (items, pick) => items.map((q) => ({ questionId: q._id, attemptedAnswer: String(pick) }));

describe('quiz routes', { skip }, () => {
    before(async () => {
        const mongoose = require('mongoose');
        jwt = require('jsonwebtoken');
        models = {
            User: require('../models/user'),
            QuizConfig: require('../models/quizConfig'),
            QuizQuestion: require('../models/quizQuestions'),
            QuizSession: require('../models/quizSession'),
            Quiz: require('../models/quiz'),
            Video: require('../models/videos'),
            VideoQuestion: require('../models/videoQuestions'),
            VideoProgress: require('../models/videoProgress'),
            VideoQuizAttempt: require('../models/videoQuizAttempt'),
            Assignment: require('../models/assignment'),
            AssignmentSubmission: require('../models/assignmentSubmission'),
            Notification: require('../models/notification'),
            UserNotification: require('../models/userNotification')
        };
        await mongoose.connect(URI);
        server = spawn(process.execPath, [path.join(__dirname, '..', 'server.js')], {
            env: { ...process.env, MONGODB_URI: URI, JWT_SECRET: SECRET, PORT: String(PORT), QUIZ_SUBMIT_GRACE_MINUTES: '5', NOTIFICATION_JOBS_SECONDS: '0' },
            stdio: ['ignore', 'pipe', 'pipe']
        });
        await new Promise((resolve, reject) => {
            const timer = setTimeout(() => reject(new Error('server did not start')), 15000);
            server.stdout.on('data', (chunk) => {
                if (String(chunk).includes('Connected to MongoDB')) { clearTimeout(timer); resolve(); }
            });
        });
    });

    after(async () => {
        const { Quiz, QuizSession, QuizQuestion, QuizConfig, User, Video, VideoQuestion, VideoProgress, VideoQuizAttempt } = models;
        await models.UserNotification.deleteMany({ userId: { $in: created.users } });
        await models.Notification.deleteMany({ _id: { $in: created.notifications } });
        await models.AssignmentSubmission.deleteMany({ assignmentId: { $in: created.assignments } });
        await models.Assignment.deleteMany({ _id: { $in: created.assignments } });
        await VideoQuizAttempt.deleteMany({ videoId: { $in: created.videos } });
        await VideoProgress.deleteMany({ videoId: { $in: created.videos } });
        await VideoQuestion.deleteMany({ videoId: { $in: created.videos } });
        await Video.deleteMany({ _id: { $in: created.videos } });
        await Quiz.deleteMany({ quizId: { $in: created.quizzes } });
        await QuizSession.deleteMany({ quizId: { $in: created.quizzes } });
        await QuizQuestion.deleteMany({ quizId: { $in: created.quizzes } });
        await QuizConfig.deleteMany({ _id: { $in: created.quizzes } });
        await User.deleteMany({ _id: { $in: created.users } });
        await require('mongoose').disconnect();
        server.kill('SIGTERM');
    });

    it('the questions come with the start time, server time and end time', async () => {
        const { token } = await student();
        const { config } = await quiz();
        const { status, body } = await call(`/api/user-quizzes/${config._id}/questions`, token);
        assert.equal(status, 200);
        assert.equal(body.questions.length, 2);
        assert.ok(body.startedAt && body.serverNow);
        assert.equal(body.endDate, config.endDate.toISOString());
    });

    it('opening again returns the same questions in the same order', async () => {
        const { token } = await student();
        const { config } = await quiz({ questions: 3, questionsRandomization: true });
        const first = await call(`/api/user-quizzes/${config._id}/questions`, token);
        const again = await call(`/api/user-quizzes/${config._id}/questions`, token);
        assert.deepEqual(again.body.questions.map((q) => q._id), first.body.questions.map((q) => q._id));
    });

    it('a submit is graded once; a repeat gets the saved result back', async () => {
        const { token } = await student();
        const { config, items } = await quiz();
        await call(`/api/user-quizzes/${config._id}/questions`, token);
        const body = { quizId: config._id, answers: answers(items), totalDuration: 10 };
        const first = await call('/api/quizzes/attempt', token, body);
        const repeat = await call('/api/quizzes/attempt', token, body);
        assert.equal(first.status, 201);
        assert.equal(first.body.attempt.score, 2);
        assert.equal(repeat.status, 409);
        assert.equal(repeat.body.attempt.attemptId, first.body.attempt.attemptId);
        assert.equal(await models.Quiz.countDocuments({ quizId: config._id }), 1);
    });

    it('an answer that took longer than the question limit is not counted', async () => {
        const { token } = await student();
        const { config, items } = await quiz({ timerMode: 'per-question', perQuestionTimeLimit: 30 });
        await call(`/api/user-quizzes/${config._id}/questions`, token);
        const late = [{ ...answers(items)[0] }, { ...answers(items)[1], duration: 45 }];
        const { body } = await call('/api/quizzes/attempt', token, { quizId: config._id, answers: late });
        assert.equal(body.attempt.score, 1);
        const saved = await models.Quiz.findOne({ quizId: config._id }).lean();
        assert.deepEqual(saved.answers.map((a) => a.status), ['answered', 'timed_out']);
        assert.equal(saved.answers[1].lateAnswer, 0);
        assert.ok(saved.startedAt);
    });

    it('started in time, sent within the grace period: accepted', async () => {
        const { user, token } = await student();
        const { config, items } = await quiz({ endDate: new Date(Date.now() - 2 * MINUTE) });
        await models.QuizSession.create({ userId: user._id, quizId: config._id, questionIds: items.map((q) => q._id) });
        const { status } = await call('/api/quizzes/attempt', token, { quizId: config._id, answers: answers(items) });
        assert.equal(status, 201);
    });

    it('started in time, sent after the grace period: refused as too late', async () => {
        const { user, token } = await student();
        const { config, items } = await quiz({ endDate: new Date(Date.now() - 10 * MINUTE) });
        await models.QuizSession.create({ userId: user._id, quizId: config._id, questionIds: items.map((q) => q._id) });
        const { status, body } = await call('/api/quizzes/attempt', token, { quizId: config._id, answers: answers(items) });
        assert.equal(status, 403);
        assert.equal(body.code, 'QUIZ_CLOSED');
    });

    it('each refusal says why', async () => {
        const { user, token } = await student();
        const prepare = async () => {
            const made = await quiz();
            await models.QuizSession.create({ userId: user._id, quizId: made.config._id, questionIds: made.items.map((q) => q._id) });
            return made;
        };
        const send = ({ config, items }) => call('/api/quizzes/attempt', token, { quizId: config._id, answers: answers(items) });

        const off = await prepare();
        await models.QuizConfig.updateOne({ _id: off.config._id }, { isEnable: false });
        assert.equal((await send(off)).body.code, 'QUIZ_DISABLED');

        const removed = await prepare();
        await models.QuizConfig.deleteOne({ _id: removed.config._id });
        assert.equal((await send(removed)).body.code, 'QUIZ_NOT_FOUND');

        const changed = await prepare();
        await models.QuizQuestion.deleteMany({ quizId: changed.config._id });
        assert.equal((await send(changed)).body.code, 'QUESTIONS_CHANGED');

        const noSession = await prepare();
        await models.QuizSession.deleteMany({ quizId: noSession.config._id });
        assert.equal((await send(noSession)).body.code, 'NO_SESSION');
    });

    it('correct answers stay hidden until the exam has closed for everyone', async () => {
        const { token } = await student();
        const { config, items } = await quiz();
        await call(`/api/user-quizzes/${config._id}/questions`, token);
        const { status, body } = await call('/api/quizzes/attempt', token, { quizId: config._id, answers: answers(items) });
        assert.equal(status, 201);
        assert.equal(body.attempt.score, 2);
        assert.equal(body.attempt.answersRevealed, false);
        assert.deepEqual(body.attempt.results, []);
        assert.equal(new Date(body.attempt.answersAvailableAt).getTime(), config.endDate.getTime() + 5 * MINUTE);

        const list = await call('/api/user-quizzes', token);
        const mine = list.body.find((q) => String(q._id) === String(config._id));
        assert.equal(mine.myAttempt.answersRevealed, false);

        await models.QuizConfig.updateOne({ _id: config._id }, { endDate: new Date(Date.now() - 10 * MINUTE) });
        const later = await call(`/api/user/quiz-attempts/${body.attempt.attemptId}`, token);
        assert.equal(later.body.answersRevealed, true);
        assert.equal(later.body.results.length, 2);
        assert.equal(later.body.results[0].correctAnswer, 0);
    });

    it('practice can be retaken and keeps the best try', async () => {
        const { user, token } = await student();
        const { video, items } = await practiceLesson(user._id);
        const send = (pick) => call('/api/user/video-quiz', token, { videoId: video._id, answers: practiceAnswers(items, pick) });

        const wrong = await send(1);
        assert.equal(wrong.status, 201);
        assert.equal(wrong.body.attempt.score, 0);
        const right = await send(0);
        assert.equal(right.body.improved, true);
        assert.equal(right.body.attempt.score, 2);
        const worse = await send(2);
        assert.equal(worse.body.improved, false);
        assert.equal(worse.body.attempt.score, 2);
        assert.equal(worse.body.attempt.latest.score, 0);
        assert.equal(worse.body.attempt.attemptCount, 3);
        assert.equal(worse.body.attempt.canRetake, true);
        assert.deepEqual(worse.body.attempt.results, []);
        assert.equal(await models.VideoQuizAttempt.countDocuments({ videoId: video._id }), 1);
    });

    it('practice answers show after the practice end date, and never without one', async () => {
        const { user, token } = await student();
        const { video, items } = await practiceLesson(user._id);
        await call('/api/user/video-quiz', token, { videoId: video._id, answers: practiceAnswers(items, 0) });
        await models.Video.updateOne({ _id: video._id }, { practiceEndDate: new Date(Date.now() - MINUTE) });
        const ended = await call(`/api/user/video-quiz?videoId=${video._id}`, token);
        assert.equal(ended.body.answersRevealed, true);
        assert.equal(ended.body.canRetake, false);
        assert.equal(ended.body.results.length, 2);
        const late = await call('/api/user/video-quiz', token, { videoId: video._id, answers: practiceAnswers(items, 0) });
        assert.equal(late.status, 403);

        const other = await student();
        const open = await practiceLesson(other.user._id, { practiceEndDate: null });
        await call('/api/user/video-quiz', other.token, { videoId: open.video._id, answers: practiceAnswers(open.items, 0) });
        const noEnd = await call(`/api/user/video-quiz?videoId=${open.video._id}`, other.token);
        assert.equal(noEnd.body.answersRevealed, false);
        assert.equal(noEnd.body.answersAvailableAt, null);
        assert.deepEqual(noEnd.body.results, []);
    });

    it('the gradebook shows marks, and marking from the queue updates it', async () => {
        const admin = jwt.sign({ username: 'it-admin', role: 'admin' }, SECRET);
        const cls = `gb-${Date.now()}`;
        const { user, token } = await student({ class: cls });
        const other = await student({ class: cls });
        const { config, items } = await quiz({ allowedClasses: [cls] });
        await call(`/api/user-quizzes/${config._id}/questions`, token);
        await call('/api/quizzes/attempt', token, { quizId: config._id, answers: answers(items) });
        const assignment = await models.Assignment.create({ title: 'Recitation', maxPoints: 10, class: cls, isPublished: true });
        created.assignments.push(assignment._id);
        const sent = await call(`/api/user/assignments/${assignment._id}/submissions`, token, { text: 'Recited twice.' });
        assert.equal(sent.status, 201);

        assert.equal((await call(`/api/admin/gradebook?class=${cls}`, token)).status, 403);
        const book = await call(`/api/admin/gradebook?class=${cls}`, admin);
        assert.equal(book.status, 200);
        assert.equal(book.body.rows.length, 2);
        const mine = book.body.rows.find((r) => r.learner.id === String(user._id));
        assert.equal(mine.cells[`exam:${config._id}`].percent, 100);
        assert.equal(mine.cells[`assignment:${assignment._id}`].status, 'needs_mark');
        const theirs = book.body.rows.find((r) => r.learner.id === String(other.user._id));
        assert.equal(theirs.cells[`assignment:${assignment._id}`].status, 'pending');
        assert.equal(book.body.needsMarking, 1);

        const queue = await call(`/api/admin/gradebook/queue?class=${cls}`, admin);
        assert.equal(queue.body.total, 1);
        const item = queue.body.items[0];
        assert.equal(item.text, 'Recited twice.');
        assert.equal(item.learner.id, String(user._id));
        const detail = await call(`/api/admin/gradebook/submissions/${item.id}`, admin);
        assert.equal(detail.body.assignment.maxPoints, 10);

        const marked = await put(`/api/admin/assignments/${assignment._id}/submissions/${item.id}`, admin, { grade: 7, feedback: 'Good', status: 'graded' });
        assert.equal(marked.status, 200);
        const after = await call(`/api/admin/gradebook?class=${cls}`, admin);
        const cell = after.body.rows.find((r) => r.learner.id === String(user._id)).cells[`assignment:${assignment._id}`];
        assert.deepEqual([cell.status, cell.value, cell.percent], ['graded', 7, 70]);
        assert.equal((await call(`/api/admin/gradebook/queue?class=${cls}`, admin)).body.total, 0);
        const classes = await call('/api/admin/gradebook/classes', admin);
        assert.ok(classes.body.includes(cls));
    });

    it('marking work puts a notification in the learner inbox that opens the assignment', async () => {
        const admin = jwt.sign({ username: 'it-admin', role: 'admin' }, SECRET);
        const cls = `nt-${Date.now()}`;
        const { token } = await student({ class: cls });
        const assignment = await models.Assignment.create({ title: 'Recitation', maxPoints: 10, class: cls, isPublished: true });
        created.assignments.push(assignment._id);
        const sent = await call(`/api/user/assignments/${assignment._id}/submissions`, token, { text: 'Recited.' });
        const submissionId = sent.body.submission.id;

        await put(`/api/admin/assignments/${assignment._id}/submissions/${submissionId}`, admin, { feedback: 'Hold the madd longer', status: 'returned' });
        await put(`/api/admin/assignments/${assignment._id}/submissions/${submissionId}`, admin, { grade: 8, feedback: 'Better', status: 'graded' });

        const inbox = await call('/api/user/notifications', token);
        assert.equal(inbox.status, 200);
        assert.equal(inbox.body.unreadCount, 2);
        const [marked, returned] = inbox.body.items;
        assert.equal(marked.kind, 'assignment_marked');
        assert.match(marked.description, /8\/10/);
        assert.deepEqual(marked.target, { kind: 'assignment', id: String(assignment._id) });
        assert.equal(returned.kind, 'assignment_returned');

        const read = await call(`/api/user/notifications/${marked._id}/read`, token, {});
        assert.equal(read.body.read, true);
        assert.equal((await call('/api/user/notifications', token)).body.unreadCount, 1);
        await call('/api/user/notifications/read-all', token, {});
        assert.equal((await call('/api/user/notifications', token)).body.unreadCount, 0);
    });

    it('an assignment past its deadline takes no new work, only work sent back for changes', async () => {
        const admin = jwt.sign({ username: 'it-admin', role: 'admin' }, SECRET);
        const cls = `dl-${Date.now()}`;
        const { token } = await student({ class: cls });
        const assignment = await models.Assignment.create({ title: 'Recitation', maxPoints: 10, class: cls, isPublished: true, dueAt: new Date(Date.now() + MINUTE) });
        created.assignments.push(assignment._id);
        const sent = await call(`/api/user/assignments/${assignment._id}/submissions`, token, { text: 'On time.' });
        assert.equal(sent.status, 201);

        await models.Assignment.updateOne({ _id: assignment._id }, { dueAt: new Date(Date.now() - MINUTE) });
        const again = await call(`/api/user/assignments/${assignment._id}/submissions`, token, { text: 'Changed my mind.' });
        assert.equal(again.status, 403);
        assert.equal(again.body.code, 'assignment_closed');

        await put(`/api/admin/assignments/${assignment._id}/submissions/${sent.body.submission.id}`, admin, { feedback: 'Redo', status: 'returned' });
        const redone = await call(`/api/user/assignments/${assignment._id}/submissions`, token, { text: 'Redone.' });
        assert.equal(redone.status, 201);
        assert.equal(redone.body.submission.status, 'late');

        const other = await student({ class: cls });
        const missed = await call(`/api/user/assignments/${assignment._id}/submissions`, other.token, { text: 'Too late.' });
        assert.equal(missed.status, 403);
    });

    it('scheduled jobs remind learners who have not sat a closing quiz, once', async () => {
        const { runNotificationJobs } = require('../services/notificationJobs');
        const cls = `job-${Date.now()}`;
        const waiting = await student({ class: cls });
        const done = await student({ class: cls });
        const { config, items } = await quiz({ allowedClasses: [cls], endDate: new Date(Date.now() + 30 * MINUTE) });
        await call(`/api/user-quizzes/${config._id}/questions`, done.token);
        await call('/api/quizzes/attempt', done.token, { quizId: config._id, answers: answers(items) });

        await runNotificationJobs(new Date());
        await runNotificationJobs(new Date());

        // Only this quiz: quizzes from other tests are open to every class.
        const kinds = async (u) => (await models.UserNotification.find({ userId: u.user._id, 'target.id': String(config._id) }).lean())
            .map((n) => n.kind).sort();
        assert.deepEqual(await kinds(waiting), ['quiz_closing', 'quiz_open']);
        assert.deepEqual(await kinds(done), []);
        const closing = await models.UserNotification.findOne({ userId: waiting.user._id, kind: 'quiz_closing', 'target.id': String(config._id) }).lean();
        assert.deepEqual(closing.target, { kind: 'quiz', id: String(config._id) });
    });

    it('announcements go to their audience at their send time', async () => {
        const { runNotificationJobs } = require('../services/notificationJobs');
        const admin = jwt.sign({ username: 'it-admin', role: 'admin' }, SECRET);
        const cls = `ann-${Date.now()}`;
        const inClass = await student({ class: cls });
        const other = await student({ class: `${cls}-other` });
        const later = new Date(Date.now() + 2 * 60 * MINUTE);
        const made = await call('/api/notifications', admin, {
            title: 'Class trip', description: 'Bring your Mushaf.',
            audience: { kind: 'class', value: cls }, target: { kind: 'none' }, sendAt: later.toISOString()
        });
        assert.equal(made.status, 201);
        created.notifications.push(made.body.notification._id);
        const bad = await call('/api/notifications', admin, { title: 'x', description: 'y', audience: { kind: 'course', value: 'nope' } });
        assert.equal(bad.status, 400);

        await runNotificationJobs(new Date());
        assert.equal((await call('/api/user/notifications', inClass.token)).body.items.filter((n) => n.title === 'Class trip').length, 0);
        await runNotificationJobs(new Date(later.getTime() + MINUTE));
        const mine = (await call('/api/user/notifications', inClass.token)).body.items.filter((n) => n.title === 'Class trip');
        assert.equal(mine.length, 1);
        assert.equal(mine[0].kind, 'announcement');
        assert.equal((await call('/api/user/notifications', other.token)).body.items.filter((n) => n.title === 'Class trip').length, 0);

        const publicList = await call('/api/notifications');
        assert.equal(publicList.body.some((n) => n.title === 'Class trip'), false);
        const adminList = await call('/api/notifications', admin);
        assert.equal(adminList.body.find((n) => n.title === 'Class trip').recipientCount, 1);
    });

    it('a phone registers for push, at most five per learner', async () => {
        const { user, token } = await student();
        for (let i = 0; i < 7; i += 1) {
            const res = await put('/api/user/notifications/push-token', token, { token: `tok-${i}`, platform: 'android' });
            assert.equal(res.status, 200);
        }
        const saved = await models.User.findById(user._id).select('+pushTokens').lean();
        assert.deepEqual(saved.pushTokens.map((t) => t.token), ['tok-2', 'tok-3', 'tok-4', 'tok-5', 'tok-6']);
    });

    it('an assignment marked by parts adds up the parts, and can switch back to one mark', async () => {
        const admin = jwt.sign({ username: 'it-admin', role: 'admin' }, SECRET);
        const cls = `rb-${Date.now()}`;
        const { token } = await student({ class: cls });
        const made = await call('/api/admin/assignments', admin, {
            title: 'Recitation', class: cls, isPublished: true, maxPoints: 50,
            rubric: { enabled: true, criteria: [{ label: 'Makharij', maxPoints: 4 }, { label: 'Madd length', maxPoints: 4 }, { label: 'Fluency', maxPoints: 2 }] }
        });
        assert.equal(made.status, 201);
        const assignmentId = made.body.assignment._id;
        created.assignments.push(assignmentId);
        assert.equal(made.body.assignment.maxPoints, 10);

        const sent = await call(`/api/user/assignments/${assignmentId}/submissions`, token, { text: 'Recited.' });
        const route = `/api/admin/assignments/${assignmentId}/submissions/${sent.body.submission.id}`;
        assert.equal((await put(route, admin, { grade: 7, status: 'graded' })).status, 400);
        const marked = await put(route, admin, { rubricScores: [3, 2, 2], feedback: 'Hold the madd longer', status: 'graded' });
        assert.equal(marked.status, 200);
        assert.equal(marked.body.submission.grade, 7);

        const mine = await call(`/api/user/assignments/${assignmentId}`, token);
        assert.deepEqual(mine.body.submission.rubricScores.map((r) => r.points), [3, 2, 2]);
        assert.equal(mine.body.rubric.enabled, true);

        const off = await put(`/api/admin/assignments/${assignmentId}`, admin, { rubric: { enabled: false, criteria: made.body.assignment.rubric.criteria }, maxPoints: 10 });
        assert.equal(off.status, 200);
        assert.equal(off.body.assignment.rubric.criteria.length, 3);
        const single = await put(route, admin, { grade: 9, status: 'graded' });
        assert.equal(single.body.submission.grade, 9);
        assert.deepEqual(single.body.submission.rubricScores, []);
    });

    it('a sign-in close to running out is renewed for 30 days', async () => {
        const { user } = await student();
        const nearlyExpired = jwt.sign({ userId: user._id.toString(), role: 'student' }, SECRET, { expiresIn: '2h' });
        const { status, body } = await call('/api/user/refresh-token', nearlyExpired, {});
        assert.equal(status, 200);
        const daysLeft = (jwt.decode(body.token).exp * 1000 - Date.now()) / (24 * 60 * MINUTE);
        assert.ok(daysLeft > 29.9 && daysLeft <= 30);
        assert.equal((await call('/api/user/me', body.token)).status, 200);
    });

    it('an expired sign-in is not renewed', async () => {
        const { user } = await student();
        const expired = jwt.sign({ userId: user._id.toString(), role: 'student', exp: Math.floor(Date.now() / 1000) - 60 }, SECRET);
        assert.equal((await call('/api/user/refresh-token', expired, {})).status, 403);
    });

    it('an older account with no role saved still signs in as a student', async () => {
        const { user, token } = await student();
        await models.User.collection.updateOne({ _id: user._id }, { $unset: { role: '' } });
        assert.equal((await call('/api/user/me', token)).status, 200);
    });

    it('a teacher with no date of birth saves one once, then signs in with it', async () => {
        const mongoose = require('mongoose');
        const phone = `9${String(Math.floor(Math.random() * 1e9)).padStart(9, '0')}`;
        const { user } = await student({ phone, role: 'faculty', facultyProfile: new mongoose.Types.ObjectId() });
        const token = jwt.sign({ userId: user._id.toString(), phone, role: 'faculty' }, SECRET);

        const blocked = await call('/api/user/login', null, { phone, dob: '1985-04-12' });
        assert.equal(blocked.status, 409);
        assert.equal(blocked.body.code, 'DOB_MISSING');

        assert.equal((await put('/api/faculty/me/dob', token, { dob: '1985-13-01' })).status, 400);
        const saved = await put('/api/faculty/me/dob', token, { dob: '1985-04-12' });
        assert.equal(saved.status, 200);
        assert.equal(saved.body.user.role, 'faculty');
        assert.ok(String(saved.body.user.dob).startsWith('1985-04-12'));
        assert.equal((await put('/api/faculty/me/dob', token, { dob: '1985-04-12' })).status, 200, 'same date again is fine');
        assert.equal((await put('/api/faculty/me/dob', token, { dob: '1990-01-01' })).status, 409, 'never changed afterwards');

        const signedIn = await call('/api/user/login', null, { phone, dob: '1985-04-12' });
        assert.equal(signedIn.status, 200);
        assert.equal(jwt.decode(signedIn.body.token).role, 'faculty');

        const learner = await student();
        assert.equal((await put('/api/faculty/me/dob', learner.token, { dob: '2010-01-01' })).status, 403);
    });

    it('a student signs in with phone and class, never with a date of birth', async () => {
        const mongoose = require('mongoose');
        const phone = `7${String(Math.floor(Math.random() * 1e9)).padStart(9, '0')}`;
        await student({ phone, class: '9', dob: new Date('2010-05-03') });
        const login = (body) => call('/api/user/login', null, { phone, ...body });

        const signedIn = await login({ class: '9' });
        assert.equal(signedIn.status, 200);
        assert.equal(jwt.decode(signedIn.body.token).role, 'student');
        assert.equal(signedIn.body.user.class, '9');
        assert.equal((await login({ class: 'Class 9' })).status, 200, 'written as on screen');
        assert.equal((await login({ class: ' 9 ' })).status, 200);

        assert.equal((await login({ class: '8' })).status, 404, 'wrong class');
        assert.equal((await login({ dob: '2010-05-03' })).status, 404, 'the date no longer signs a student in');
        assert.equal((await login({})).status, 400);
        assert.equal((await call('/api/user/login', null, { phone: `6${phone.slice(1)}`, class: '9' })).status, 404, 'unknown number');

        const teacherPhone = `4${String(Math.floor(Math.random() * 1e9)).padStart(9, '0')}`;
        await student({ phone: teacherPhone, class: 'Faculty', role: 'faculty', facultyProfile: new mongoose.Types.ObjectId(), dob: new Date('1985-04-12') });
        assert.equal((await call('/api/user/login', null, { phone: teacherPhone, class: 'Faculty' })).status, 404, 'a class never signs a teacher in');
        assert.equal((await call('/api/user/login', null, { phone: teacherPhone, dob: '1985-04-12' })).status, 200);
    });

    it('registration no longer asks for a date of birth', async () => {
        const phone = `5${String(Math.floor(Math.random() * 1e9)).padStart(9, '0')}`;
        const registered = await call('/api/user/register', null, { name: 'New Learner', phone, class: '7' });
        assert.equal(registered.status, 201);
        created.users.push(registered.body.user.id);
        assert.equal(registered.body.user.dob, null);
        assert.equal((await call('/api/user/login', null, { phone, class: '7' })).status, 200);
    });

    it('the admin adds a missing teacher date of birth and can correct it', async () => {
        const mongoose = require('mongoose');
        const phone = `8${String(Math.floor(Math.random() * 1e9)).padStart(9, '0')}`;
        const { user } = await student({ phone, role: 'faculty', facultyProfile: new mongoose.Types.ObjectId() });
        const admin = jwt.sign({ username: 'it-admin', role: 'admin' }, SECRET);
        const route = `/api/admin/users/${user._id}`;
        const fields = { name: 'Integration', phone, class: '8' };
        const login = (dob) => call('/api/user/login', null, { phone, dob });

        assert.equal((await login('2010-05-03')).body.code, 'DOB_MISSING');
        assert.equal((await put(route, admin, { ...fields, dob: '2010-02-31' })).status, 400);
        assert.equal((await put(route, admin, { ...fields, dob: '2999-01-01' })).status, 400);

        const added = await put(route, admin, { ...fields, dob: '2010-05-03' });
        assert.equal(added.status, 200);
        assert.ok(String(added.body.user.dob).startsWith('2010-05-03'));
        assert.equal((await login('2010-05-03')).status, 200);

        const kept = await put(route, admin, { ...fields, class: '9', dob: '' });
        assert.equal(kept.status, 200);
        assert.ok(String(kept.body.user.dob).startsWith('2010-05-03'), 'an empty date keeps the saved one');

        assert.equal((await put(route, admin, { ...fields, dob: '2010-06-04' })).status, 200);
        assert.equal((await login('2010-06-04')).status, 200);
        assert.equal((await login('2010-05-03')).status, 404, 'the old date no longer signs in');

        const { token } = await student();
        assert.equal((await put(route, token, { ...fields, dob: '2011-01-01' })).status, 403, 'admins only');
    });

    it('editing an uploaded video keeps its file unless the address really changes', async () => {
        const mongoose = require('mongoose');
        const uploaded = 'https://cdn.example.com/videos/it-lesson.mp4';
        const video = await models.Video.create({
            title: 'Uploaded Lesson', video: uploaded, videoKey: 'videos/it-lesson.mp4', subject: new mongoose.Types.ObjectId()
        });
        created.videos.push(video._id);
        const admin = jwt.sign({ username: 'it-admin', role: 'admin' }, SECRET);
        const route = `/api/videos/${video._id}`;

        // The edit form sends the current address back with every save.
        assert.equal((await put(route, admin, { title: 'Renamed Lesson', video: uploaded })).status, 200);
        let saved = await models.Video.findById(video._id).lean();
        assert.equal(saved.title, 'Renamed Lesson');
        assert.equal(saved.video, uploaded);
        assert.equal(saved.videoKey, 'videos/it-lesson.mp4', 'the stored file is kept');

        assert.equal((await put(route, admin, { video: 'https://youtu.be/integration' })).status, 200);
        saved = await models.Video.findById(video._id).lean();
        assert.equal(saved.video, 'https://youtu.be/integration');
        assert.equal(saved.videoKey, null, 'a new address replaces the stored file');
    });

    it('practice marks the button picked, even when the options are numbers', async () => {
        // "What is 1 + 1?" with buttons 1, 2, 3, 4: the right one is the 2nd (button 1).
        const numbers = JSON.stringify(['1', '2', '3', '4']);
        const pick = async (button) => {
            const { user, token } = await student();
            const { video, items } = await practiceLesson(user._id);
            await models.VideoQuestion.updateMany({ videoId: video._id }, { options_en: numbers, options_ml: numbers, correct_answer: '2' });
            const sent = await call('/api/user/video-quiz', token, { videoId: video._id, answers: practiceAnswers(items, button) });
            assert.equal(sent.status, 201);
            return sent.body.attempt.score;
        };

        assert.equal(await pick(2), 0, 'the 3rd button ("3") is wrong, though the app sends "2"');
        assert.equal(await pick(1), 2, 'the 2nd button ("2") is right');
        assert.equal(await pick(-1), 0, 'unanswered');

        const { user, token } = await student();
        const { video, items } = await practiceLesson(user._id);
        const text = await call('/api/user/video-quiz', token, { videoId: video._id, answers: items.map((q) => ({ questionId: q._id, attemptedAnswer: 'A' })) });
        assert.equal(text.body.attempt.score, 0, 'only button numbers are marked');
    });

    it('an unreleased lesson shows students only its coming-soon card, and no storage file name ever', async () => {
        const mongoose = require('mongoose');
        const subject = new mongoose.Types.ObjectId();
        const upcoming = await models.Video.create({
            title: 'Coming Lesson', description: 'secret notes', video: 'https://cdn.example.com/videos/coming.mp4', videoKey: 'videos/coming.mp4',
            subject, order: 2, releaseDate: new Date(Date.now() + 24 * 60 * MINUTE).toISOString(),
            learnText: 'secret', downloads: [{ title: 'Handout', url: 'https://cdn.example.com/handouts/h.pdf', key: 'handouts/h.pdf' }]
        });
        const released = await models.Video.create({
            title: 'Released Lesson', video: 'https://cdn.example.com/videos/out.mp4', videoKey: 'videos/out.mp4', subject, order: 1
        });
        created.videos.push(upcoming._id, released._id);
        const card = ['_id', 'isUpcoming', 'order', 'questionCount', 'releaseDate', 'speaker', 'subject', 'title', 'video'];

        const one = await call(`/api/videos/${upcoming._id}`);
        assert.deepEqual(Object.keys(one.body).sort(), card);
        assert.equal(one.body.video, '');
        assert.equal(one.body.isUpcoming, true);

        const list = await call(`/api/videos?subject=${subject}`);
        assert.deepEqual(Object.keys(list.body.find((v) => v._id === String(upcoming._id))).sort(), card);
        const out = list.body.find((v) => v._id === String(released._id));
        assert.equal(out.video, 'https://cdn.example.com/videos/out.mp4');
        assert.equal(out.videoKey, undefined, 'students never get the storage file name');

        const { user, token } = await student();
        await models.User.updateOne({ _id: user._id }, { bookmarks: [upcoming._id, released._id] });
        const saved = await call('/api/user/bookmarks', token);
        assert.deepEqual(Object.keys(saved.body.find((v) => v._id === String(upcoming._id))).sort(), card);
        assert.equal(saved.body.find((v) => v._id === String(released._id)).videoKey, undefined);

        const admin = jwt.sign({ username: 'it-admin', role: 'admin' }, SECRET);
        const full = await call(`/api/videos/${upcoming._id}`, admin);
        assert.equal(full.body.videoKey, 'videos/coming.mp4', 'the admin still sees everything');
    });

    it('a phone number the admin types with +91 or spaces still signs the student in', async () => {
        const digits = `8${String(Math.floor(Math.random() * 1e9)).padStart(9, '0')}`;
        const { user } = await student({ phone: digits });
        const admin = jwt.sign({ username: 'it-admin', role: 'admin' }, SECRET);
        const route = `/api/admin/users/${user._id}`;
        const fields = { name: 'Integration', class: '8' };

        const typed = `+91 ${digits.slice(0, 5)} ${digits.slice(5)}`;
        assert.equal((await put(route, admin, { ...fields, phone: typed })).status, 200);
        assert.equal((await models.User.findById(user._id).lean()).phone, digits, 'saved as the 10 digits');
        assert.equal((await call('/api/user/login', null, { phone: digits, class: '8' })).status, 200);

        assert.equal((await put(route, admin, { ...fields, phone: '12345' })).status, 400, 'not a 10-digit number');
        const { user: other } = await student({ phone: `7${digits.slice(1)}` });
        assert.equal((await put(route, admin, { ...fields, phone: `0${other.phone}` })).status, 409, 'already used by another account');
    });

    it('admin search takes any symbol, and finds a student by a number typed with +91', async () => {
        const digits = `6${String(Math.floor(Math.random() * 1e9)).padStart(9, '0')}`;
        const { user } = await student({ phone: digits });
        const admin = jwt.sign({ username: 'it-admin', role: 'admin' }, SECRET);
        const users = (search) => call(`/api/admin/users?search=${encodeURIComponent(search)}`, admin);

        const byPhone = await users(`+91 ${digits.slice(0, 5)} ${digits.slice(5)}`);
        assert.equal(byPhone.status, 200);
        assert.ok(byPhone.body.items.some((u) => String(u._id) === String(user._id)));
        for (const search of ['(', '+', 'a+b@x.com', '[']) {
            assert.equal((await users(search)).status, 200, search);
        }

        const { config } = await quiz();
        assert.equal((await call(`/api/quiz-definitions/${config._id}/results?search=${encodeURIComponent('(')}`, admin)).status, 200);
    });

    it('the admin Q&A list pages on the server, with search, answered and teacher filters', async () => {
        const Speaker = require('../models/speakers');
        const Question = require('../models/question');
        const tag = `qa${Date.now()}`;
        const teacher = await Speaker.create({ name: `Teacher ${tag}`, image: 'https://example.com/t.png' });
        const other = await Speaker.create({ name: `Other ${tag}`, image: 'https://example.com/o.png' });
        const { user } = await student({ name: `Asker ${tag}` });
        const rows = [];
        for (let i = 0; i < 25; i += 1) {
            rows.push({ description: `${tag} question ${i}`, subject: 'Fiqh', user: user._id, faculty: i < 20 ? teacher._id : other._id, answer: i < 5 ? 'Answered.' : null });
        }
        const made = await Question.insertMany(rows);
        const admin = jwt.sign({ username: 'it-admin', role: 'admin' }, SECRET);
        const list = (query) => call(`/api/questions/admin?${new URLSearchParams(query)}`, admin);

        try {
            const first = await list({ search: tag, limit: 10, page: 1 });
            assert.equal(first.body.items.length, 10);
            assert.equal(first.body.total, 25);
            const third = await list({ search: tag, limit: 10, page: 3 });
            assert.equal(third.body.items.length, 5);

            assert.equal((await list({ search: tag, answered: 'true' })).body.total, 5);
            assert.equal((await list({ search: tag, answered: 'false' })).body.total, 20);
            assert.equal((await list({ search: tag, faculty: other.name })).body.total, 5);
            assert.equal((await list({ search: `Asker ${tag}` })).body.total, 25, 'search finds the student name too');
            assert.equal((await list({ search: '(' })).status, 200);

            const counts = first.body.counts;
            assert.ok(counts.all >= 25 && counts.answered >= 5 && counts.pending >= 20);
            assert.equal(counts.all, counts.answered + counts.pending);
        } finally {
            await Question.deleteMany({ _id: { $in: made.map((q) => q._id) } });
            await Speaker.deleteMany({ _id: { $in: [teacher._id, other._id] } });
        }
    });

    it('the admin assignment list pages on the server, with search, status tabs and totals', async () => {
        const tag = `as${Date.now()}`;
        const past = new Date(Date.now() - 24 * 60 * MINUTE);
        const future = new Date(Date.now() + 24 * 60 * MINUTE);
        const rows = [];
        for (let i = 0; i < 25; i += 1) {
            // 0-9 published and overdue, 10-19 published and due later, 20-24 drafts with no deadline.
            rows.push({ title: `${tag} ${i}`, instructions: i === 7 ? `find ${tag}-marker` : '', maxPoints: 10, isPublished: i < 20, dueAt: i < 10 ? past : i < 20 ? future : null });
        }
        const made = await models.Assignment.insertMany(rows);
        created.assignments.push(...made.map((a) => a._id));
        const admin = jwt.sign({ username: 'it-admin', role: 'admin' }, SECRET);
        const list = (query) => call(`/api/admin/assignments?${new URLSearchParams(query)}`, admin);

        const first = await list({ search: tag, limit: 10, page: 1 });
        assert.equal(first.body.items.length, 10);
        assert.equal(first.body.total, 25);
        const last = await list({ search: tag, limit: 10, page: 3 });
        assert.equal(last.body.items.length, 5);
        assert.ok(last.body.items.every((a) => a.dueAt === null), 'no deadline comes last');

        assert.equal((await list({ search: tag, status: 'published' })).body.total, 20);
        assert.equal((await list({ search: tag, status: 'draft' })).body.total, 5);
        assert.equal((await list({ search: tag, status: 'overdue' })).body.total, 10);
        assert.equal((await list({ search: `${tag}-marker` })).body.total, 1, 'search reads the instructions too');
        assert.equal((await list({ search: '(' })).status, 200);

        const { counts } = first.body;
        assert.ok(counts.all >= 25 && counts.published >= 20 && counts.overdue >= 10);
        assert.equal(typeof counts.needsReview, 'number');
    });

    it('Today lists only the quizzes this student may open, like the Quizzes screen', async () => {
        const { token } = await student({ class: '8' });
        const quizTotal = async () => (await call('/api/user/today', token)).body.summary.quizzes.total;
        const before = await quizTotal();

        await quiz({ allowedClasses: ['10'] });
        assert.equal(await quizTotal(), before, 'a Class 10 quiz is not counted for Class 8');
        await quiz({ conditions: { requireCompletedVideo: true } });
        assert.equal(await quizTotal(), before, 'nor one that needs a finished video first');
        await quiz({ allowedClasses: ['8'] });
        assert.equal(await quizTotal(), before + 1, 'a Class 8 quiz is');
    });

    it('XP and the best streak never go down when old learning events are trimmed', async () => {
        const mongoose = require('mongoose');
        // An account from before running totals: 500 finished quizzes (25 XP each), all on one day.
        const events = Array.from({ length: 500 }, (_, i) => ({
            type: 'quiz_completed', sourceType: 'quiz', sourceId: new mongoose.Types.ObjectId(), dayKey: '2026-01-01', occurredAt: new Date(Date.UTC(2026, 0, 1, 0, 0, i))
        }));
        const { user, token } = await student({ learningEvents: events });
        await models.User.collection.updateOne({ _id: user._id }, { $set: { bestStreak: 30 } });
        const stats = async () => (await call('/api/user/learning-stats', token)).body;

        const before = await stats();
        assert.equal(before.xp, 12500);
        assert.equal(before.longestStreak, 30, 'a longer streak from events trimmed long ago is kept');

        // A 501st event trims the oldest finished quiz from the list.
        const { video } = await practiceLesson(user._id);
        assert.equal((await call('/api/user/learning-stats/note-read', token, { videoId: video._id })).status, 201);
        assert.equal((await models.User.findById(user._id).lean()).learningEvents.length, 500);
        assert.equal((await stats()).xp, 12505, 'the note adds 5; the trimmed quiz keeps its 25');
    });

    it('the admin assignment list says how much work is waiting to be marked', async () => {
        const title = `Awaiting ${Date.now()}`;
        const assignment = await models.Assignment.create({ title, maxPoints: 10, isPublished: true });
        created.assignments.push(assignment._id);
        for (const status of ['submitted', 'late', 'graded', 'returned']) {
            const { user } = await student();
            await models.AssignmentSubmission.create({ assignmentId: assignment._id, userId: user._id, status, text: status });
        }
        const admin = jwt.sign({ username: 'it-admin', role: 'admin' }, SECRET);

        const list = await call(`/api/admin/assignments?search=${encodeURIComponent(title)}`, admin);
        assert.equal(list.status, 200);
        const item = list.body.items.find((entry) => entry.id === String(assignment._id));
        assert.equal(item.submissionCount, 4);
        assert.equal(item.pendingSubmissions, 2, 'submitted and late work waits for marking; graded and returned do not');
    });
});
