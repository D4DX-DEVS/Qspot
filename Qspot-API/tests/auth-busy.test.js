const test = require('node:test');
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const User = require('../models/user');
const { authenticateUser, authenticateFaculty } = require('../middlewares/auth');

process.env.JWT_SECRET = process.env.JWT_SECRET || 'auth-busy-secret';

// Runs one middleware and returns the reply status and message (or "next").
const run = async (middleware, token) => {
    const req = { headers: { authorization: `Bearer ${token}` } };
    let reply = 'next';
    const res = {
        status(code) { reply = { status: code }; return this; },
        json(body) { reply.message = body.message; return this; }
    };
    await middleware(req, res, () => {});
    return reply;
};

const sign = (role) => jwt.sign({ userId: '64b000000000000000000001', role }, process.env.JWT_SECRET);

test('a busy database is not a sign-out: students and teachers get "try again", not "expired"', async (t) => {
    const original = User.findById;
    t.after(() => { User.findById = original; });
    const busy = () => Promise.reject(new Error('Timed out while checking out a connection from connection pool'));
    User.findById = () => {
        const query = busy();
        query.catch(() => {});
        return Object.assign(query, { select: () => ({ lean: busy }) });
    };

    for (const [middleware, role] of [[authenticateUser, 'student'], [authenticateFaculty, 'faculty']]) {
        const reply = await run(middleware, sign(role));
        assert.equal(reply.status, 503, role);
        assert.notEqual(reply.message, 'Invalid or expired token', role);
    }
});

test('a bad or expired token is still refused as before', async () => {
    const expired = jwt.sign({ userId: 'x', role: 'student', exp: Math.floor(Date.now() / 1000) - 60 }, process.env.JWT_SECRET);
    for (const middleware of [authenticateUser, authenticateFaculty]) {
        assert.deepEqual(await run(middleware, 'not-a-token'), { status: 403, message: 'Invalid or expired token' });
        assert.deepEqual(await run(middleware, expired), { status: 403, message: 'Invalid or expired token' });
    }
});
