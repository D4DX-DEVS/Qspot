// Simulates a classroom starting and submitting a quiz at the same moment.
//
//   MONGODB_URI=mongodb://127.0.0.1:27017/qspot_load JWT_SECRET=... \
//   BASE_URL=http://127.0.0.1:5001 node scripts/load-test-quiz.js [students=500]
//
// Start the API (npm start) against the SAME MONGODB_URI/JWT_SECRET first.
// It seeds fake students + a live quiz, fires every student at once through
// three phases (start, submit, duplicate submit), checks the database, then
// deletes everything it created. Safety: it refuses to run unless the database
// is on this machine and its name contains "load" or "test".
require('dotenv').config();
const http = require('http');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const User = require('../models/user');
const QuizConfig = require('../models/quizConfig');
const QuizQuestion = require('../models/quizQuestions');
const QuizSession = require('../models/quizSession');
const Quiz = require('../models/quiz');

const STUDENTS = Number(process.argv[2]) || 500;
const BASE_URL = process.env.BASE_URL || 'http://127.0.0.1:5001';
const REQUEST_TIMEOUT_MS = 30000;
// Requests are all fired at once, but share a bounded keep-alive pool, the way
// a load balancer talks to the app. 500 raw sockets in the same millisecond can
// overflow a laptop's TCP accept queue (macOS: 128) and say nothing about the API.
const CONNECTIONS = Number(process.env.CONNECTIONS) || 100;
const agent = new http.Agent({ keepAlive: true, maxSockets: CONNECTIONS, maxFreeSockets: CONNECTIONS });
const QUESTION_POOL = 40;
const QUESTIONS_PER_STUDENT = 20;

const assertLocalTestDb = (uri) => {
    const match = /^mongodb:\/\/(?:[^@/]*@)?([^/:,]+)(?::\d+)?\/([^?]+)/.exec(uri || '');
    const host = match?.[1];
    const name = match?.[2] || '';
    if (!['127.0.0.1', 'localhost'].includes(host) || !/load|test/i.test(name)) {
        console.error('Refusing to run: MONGODB_URI must be a local database whose name contains "load" or "test".');
        process.exit(1);
    }
};

const percentile = (sorted, p) => sorted[Math.min(sorted.length - 1, Math.floor((p / 100) * sorted.length))];

const send = ({ url, token, body }) => new Promise((resolve) => {
    const t0 = Date.now();
    const payload = body ? JSON.stringify(body) : null;
    const req = http.request(url, {
        agent,
        method: body ? 'POST' : 'GET',
        timeout: REQUEST_TIMEOUT_MS,
        headers: {
            Authorization: `Bearer ${token}`,
            ...(payload ? { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) } : {})
        }
    }, (res) => {
        let text = '';
        res.on('data', (chunk) => { text += chunk; });
        res.on('end', () => {
            let json = null;
            try { json = JSON.parse(text); } catch (e) { /* not JSON */ }
            resolve({ status: res.statusCode, ms: Date.now() - t0, json });
        });
    });
    req.on('timeout', () => req.destroy(new Error('TIMEOUT')));
    req.on('error', (error) => resolve({ status: `ERR:${error.code || error.message}`, ms: Date.now() - t0, json: null }));
    req.end(payload);
});

// Opens the keep-alive pool 50 connections at a time, like a load balancer's
// standing connections, so the phases below measure the API and not how fast
// this machine accepts a flood of brand-new sockets.
const warmUp = async () => {
    for (let open = 50; open <= CONNECTIONS; open += 50) {
        await Promise.all(Array.from({ length: open }, () => send({ url: `${BASE_URL}/healthz`, token: '' })));
    }
};

// Sends every request at once and reports status codes + latency.
const blast = async (label, requests) => {
    const started = Date.now();
    const results = await Promise.all(requests.map(send));
    const byStatus = {};
    results.forEach((r) => { byStatus[r.status] = (byStatus[r.status] || 0) + 1; });
    const times = results.map((r) => r.ms).sort((a, b) => a - b);
    console.log(`\n[${label}] ${requests.length} requests in ${Date.now() - started} ms`);
    console.log('  status :', JSON.stringify(byStatus));
    console.log(`  latency: p50 ${percentile(times, 50)} ms  p95 ${percentile(times, 95)} ms  p99 ${percentile(times, 99)} ms  max ${times[times.length - 1]} ms`);
    return results;
};

// Answers with the time taken per question, as the app sends them.
const answersFor = (questions) => questions.map((q) => ({
    questionId: q._id, attemptedAnswer: Math.floor(Math.random() * 4), duration: 1
}));

const main = async () => {
    assertLocalTestDb(process.env.MONGODB_URI);
    if (!process.env.JWT_SECRET) throw new Error('JWT_SECRET is required (same value the API uses).');
    await mongoose.connect(process.env.MONGODB_URI);

    const runId = Date.now();
    const created = { users: [], quizzes: [] };
    let failed = false;
    try {
        const users = await User.insertMany(Array.from({ length: STUDENTS }, (_, i) => ({
            name: `Load Student ${i}`, phone: `load-${runId}-${i}`, class: '8', role: 'student'
        })));
        created.users = users.map((u) => u._id);
        const tokens = users.map((u) => jwt.sign({ userId: u._id.toString(), role: 'student' }, process.env.JWT_SECRET));

        const makeQuiz = async (title) => {
            const quiz = await QuizConfig.create({
                title, startDate: new Date(Date.now() - 3600e3), endDate: new Date(Date.now() + 3600e3),
                numberOfQuestions: QUESTIONS_PER_STUDENT, questionsRandomization: true, isEnable: true
            });
            created.quizzes.push(quiz._id);
            await QuizQuestion.insertMany(Array.from({ length: QUESTION_POOL }, (_, i) => ({
                quizId: quiz._id, type: 'Multiple Choice', question_en: `Question ${i}?`, question_ml: `Question ${i}?`,
                options_en: JSON.stringify(['A', 'B', 'C', 'D']), options_ml: JSON.stringify(['A', 'B', 'C', 'D']),
                correct_answer: 'A', difficulty: 'easy'
            })));
            return quiz._id.toString();
        };
        await warmUp();
        console.log(`Seeded ${STUDENTS} students, ${CONNECTIONS} connections open, against ${BASE_URL}`);

        // Phase 1+2: everyone starts, then everyone submits, at the same moment.
        const quizA = await makeQuiz(`LOAD TEST A ${runId}`);
        const started = await blast('start quiz', tokens.map((token) => ({ url: `${BASE_URL}/api/user-quizzes/${quizA}/questions`, token })));
        const questionsOf = started.map((r) => r.json?.questions || []);
        // Reopening (app restarted, second device) must hand back the SAME questions.
        const reopened = await blast('reopen quiz', tokens.map((token) => ({ url: `${BASE_URL}/api/user-quizzes/${quizA}/questions`, token })));
        const changedSet = reopened.filter((r, i) =>
            JSON.stringify((r.json?.questions || []).map((q) => q._id)) !== JSON.stringify(questionsOf[i].map((q) => q._id))).length;
        const submitted = await blast('submit quiz', tokens.map((token, i) => ({
            url: `${BASE_URL}/api/quizzes/attempt`, token,
            body: { quizId: quizA, language: 'English', answers: answersFor(questionsOf[i]), totalDuration: 60 }
        })));

        // Phase 3: a retry racing the original request (slow network, double tap).
        const quizB = await makeQuiz(`LOAD TEST B ${runId}`);
        const startedB = await blast('start quiz (B)', tokens.map((token) => ({ url: `${BASE_URL}/api/user-quizzes/${quizB}/questions`, token })));
        const doubles = tokens.flatMap((token, i) => {
            const request = { url: `${BASE_URL}/api/quizzes/attempt`, token,
                body: { quizId: quizB, language: 'English', answers: answersFor(startedB[i].json?.questions || []), totalDuration: 60 } };
            return [request, request];
        });
        const doubled = await blast('duplicate submit (2 per student, same instant)', doubles);

        // What the database ended up with.
        const attemptsA = await Quiz.countDocuments({ quizId: quizA });
        const attemptsB = await Quiz.countDocuments({ quizId: quizB });
        const wrongSize = await Quiz.countDocuments({ quizId: { $in: created.quizzes }, $expr: { $ne: [{ $size: '$answers' }, QUESTIONS_PER_STUDENT] } });
        const noAttemptBody = doubled.filter((r) => r.status === 409 && !r.json?.attempt).length;
        const noTiming = await Quiz.countDocuments({ quizId: { $in: created.quizzes }, 'answers.status': { $exists: false } });
        const lost = submitted.filter((r) => r.status !== 201).length;

        console.log('\n--- verdict ---');
        console.log(`submit phase: ${STUDENTS - lost}/${STUDENTS} accepted, attempts stored: ${attemptsA}`);
        console.log(`duplicate phase: attempts stored: ${attemptsB} (want exactly ${STUDENTS}); 409s without a result body: ${noAttemptBody} (want 0)`);
        console.log(`attempts with the wrong number of answers: ${wrongSize} (want 0)`);
        console.log(`students given a different question set on reopen: ${changedSet} (want 0)`);
        console.log(`attempts stored without per-question timing: ${noTiming} (want 0)`);
        failed = noTiming > 0 || changedSet > 0 || lost > 0 || attemptsA !== STUDENTS || attemptsB !== STUDENTS || noAttemptBody > 0 || wrongSize > 0;
        console.log(failed ? 'RESULT: FAIL' : 'RESULT: PASS');
    } finally {
        await Quiz.deleteMany({ quizId: { $in: created.quizzes } });
        await QuizSession.deleteMany({ quizId: { $in: created.quizzes } });
        await QuizQuestion.deleteMany({ quizId: { $in: created.quizzes } });
        await QuizConfig.deleteMany({ _id: { $in: created.quizzes } });
        await User.deleteMany({ _id: { $in: created.users } });
        await mongoose.disconnect();
    }
    process.exit(failed ? 1 : 0);
};

main().catch((error) => { console.error(error); process.exit(1); });
