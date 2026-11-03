const test = require('node:test');
const assert = require('node:assert/strict');
const { sendPush, pickProvider, providers } = require('../services/pushSender');

test('nothing is pushed unless a service is chosen', async () => {
    assert.equal(pickProvider(undefined), providers.none);
    assert.equal(pickProvider('unknown'), providers.none);
    assert.deepEqual(await sendPush(['t1'], { title: 'Hi' }), { sent: 0 });
});

test('phones with no token are skipped without calling the service', async () => {
    let called = false;
    const fake = { send: async () => { called = true; return { sent: 1 }; } };
    assert.deepEqual(await sendPush([], { title: 'Hi' }, fake), { sent: 0 });
    assert.equal(called, false);
});

test('a failing service never throws', async () => {
    const original = console.error;
    console.error = () => {};
    try {
        const broken = { send: async () => { throw new Error('down'); } };
        const result = await sendPush(['t1'], { title: 'Hi' }, broken);
        assert.equal(result.sent, 0);
    } finally {
        console.error = original;
    }
});
