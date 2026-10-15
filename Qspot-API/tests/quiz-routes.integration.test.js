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
const created = { users: [], quizzes: [] };

const call = async (route, token, body) => {
    const res = await fetch(BASE + route, {
        method: body ? 'POST' : 'GET',
        headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
        body: body ? JSON.stringify(body) : undefined
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

describe('quiz routes', { skip }, () => {
    before(async () => {
        const mongoose = require('mongoose');
        jwt = require('jsonwebtoken');
        models = {
            User: require('../models/user'),
            QuizConfig: require('../models/quizConfig'),
            QuizQuestion: require('../models/quizQuestions'),
            QuizSession: require('../models/quizSession'),
            Quiz: require('../models/quiz')
        };
        await mongoose.connect(URI);
        server = spawn(process.execPath, [path.join(__dirname, '..', 'server.js')], {
            env: { ...process.env, MONGODB_URI: URI, JWT_SECRET: SECRET, PORT: String(PORT), QUIZ_SUBMIT_GRACE_MINUTES: '5' },
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
        const { Quiz, QuizSession, QuizQuestion, QuizConfig, User } = models;
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
});
