const test = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const { adminLoginLimiter, MAX_FAILED_ADMIN } = require('../middlewares/loginLimiter');

// A stand-in for the admin login: password "good" signs in, anything else fails.
const startServer = async () => {
    const app = express();
    app.use(express.json());
    app.post('/admin/login', adminLoginLimiter(), (req, res) =>
        req.body.password === 'good' ? res.json({ ok: true }) : res.status(401).json({ message: 'Invalid credentials' }));
    const server = await new Promise((resolve) => {
        const s = app.listen(0, () => resolve(s));
    });
    const post = async (password) => (await fetch(`http://127.0.0.1:${server.address().port}/admin/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: 'admin', password })
    })).status;
    return { post, close: () => server.close() };
};

test('admin login waits after 5 wrong passwords, even for the right one', async () => {
    assert.equal(MAX_FAILED_ADMIN, 5);
    const { post, close } = await startServer();
    try {
        for (let i = 0; i < MAX_FAILED_ADMIN; i += 1) {
            assert.equal(await post('wrong'), 401);
        }
        assert.equal(await post('wrong'), 429);
        assert.equal(await post('good'), 429, 'guessing has to stop, so the right password waits too');
    } finally {
        close();
    }
});

test('successful admin logins never use up the allowance', async () => {
    const { post, close } = await startServer();
    try {
        for (let i = 0; i < MAX_FAILED_ADMIN * 3; i += 1) {
            assert.equal(await post('good'), 200);
        }
    } finally {
        close();
    }
});
