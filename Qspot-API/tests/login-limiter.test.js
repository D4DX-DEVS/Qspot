const test = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const {
    loginPhoneLimiter,
    loginIpLimiter,
    phoneKey,
    MAX_FAILED_PER_PHONE,
    MAX_FAILED_PER_IP
} = require('../middlewares/loginLimiter');

// A stand-in for the real login: dob "good" signs in, anything else fails.
const startServer = async () => {
    const app = express();
    app.use(express.json());
    app.post('/login', loginIpLimiter(), loginPhoneLimiter(), (req, res) =>
        req.body.dob === 'good' ? res.json({ ok: true }) : res.status(404).json({ message: 'no match' }));
    const server = await new Promise((resolve) => {
        const s = app.listen(0, () => resolve(s));
    });
    const post = async (phone, dob) => (await fetch(`http://127.0.0.1:${server.address().port}/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone, dob })
    })).status;
    return { post, close: () => server.close() };
};

test('the same number is blocked after its failed attempts, however it is written', async () => {
    const { post, close } = await startServer();
    try {
        for (let i = 0; i < MAX_FAILED_PER_PHONE; i += 1) {
            assert.equal(await post('9876543210', 'bad'), 404);
        }
        assert.equal(await post('9876543210', 'bad'), 429);
        assert.equal(await post('+91 98765 43210', 'bad'), 429, 'same number with +91');
        assert.equal(await post('9876543210', 'good'), 429, 'even the right date waits');
    } finally {
        close();
    }
});

test('a different number is not affected', async () => {
    const { post, close } = await startServer();
    try {
        for (let i = 0; i < MAX_FAILED_PER_PHONE; i += 1) await post('9876543210', 'bad');
        assert.equal(await post('9123456789', 'good'), 200);
    } finally {
        close();
    }
});

test('successful sign-ins never use up the allowance', async () => {
    const { post, close } = await startServer();
    try {
        for (let i = 0; i < MAX_FAILED_PER_PHONE * 3; i += 1) {
            assert.equal(await post('9876543210', 'good'), 200);
        }
    } finally {
        close();
    }
});

test('one device cannot try many numbers without limit', async () => {
    const { post, close } = await startServer();
    try {
        for (let i = 0; i < MAX_FAILED_PER_IP; i += 1) {
            assert.equal(await post(`90000000${String(i).padStart(2, '0')}`, 'bad'), 404);
        }
        assert.equal(await post('9111111111', 'bad'), 429);
        assert.equal(await post('9222222222', 'good'), 429);
    } finally {
        close();
    }
});

test('phoneKey ignores formatting and missing bodies', () => {
    assert.equal(phoneKey({ body: { phone: '+91 98765-43210' } }), 'phone:9876543210');
    assert.equal(phoneKey({ body: { phone: '09876543210' } }), 'phone:9876543210');
    assert.equal(phoneKey({ body: {} }), 'phone:');
    assert.equal(phoneKey({}), 'phone:');
});
