// Local API integration check: creates one temporary lesson and removes it.
require('dotenv').config({ quiet: true });
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const jwt = require('jsonwebtoken');
const API = process.env.LOCAL_API_URL || 'http://localhost:5001';
const fixtures = path.join(__dirname, 'fixtures', 'learn-demo');

async function main() {
    assert.notEqual(process.env.NODE_ENV, 'production');
    assert.match(process.env.MONGODB_URI || '', /^mongodb:\/\/(localhost|127\.0\.0\.1)(:\d+)?\//);
    assert.ok(['localhost', '127.0.0.1'].includes(new URL(API).hostname));
    const admin = jwt.sign({ role: 'admin' }, process.env.JWT_SECRET, { expiresIn: '5m' });
    const student = jwt.sign({ role: 'student' }, process.env.JWT_SECRET, { expiresIn: '5m' });
    const headers = { Authorization: `Bearer ${admin}`, 'Content-Type': 'application/json' };
    const videos = await (await fetch(`${API}/api/videos`)).json();
    const source = videos.find((video) => video.subject?._id && video.video);
    assert.ok(source, 'Seed a local lesson before running this check.');
    const created = await fetch(`${API}/api/videos`, { method: 'POST', headers, body: JSON.stringify({
        title: `Temporary material check ${Date.now()}`, subject: source.subject._id, video: source.video,
        practiceEnabled: false
    }) });
    assert.equal(created.status, 201);
    const id = (await created.json()).video._id;
    const base = `${API}/api/videos/${id}`;
    const upload = (files, token = admin) => {
        const form = new FormData();
        for (const [name, type, bytes] of files) form.append('files', new Blob([bytes], { type }), name);
        return fetch(`${base}/files`, { method: 'POST', headers: token ? { Authorization: `Bearer ${token}` } : {}, body: form });
    };
    let attached = [];
    try {
        const text = [['notes.txt', 'text/plain', 'Sample note']];
        assert.equal((await upload(text, null)).status, 401);
        assert.equal((await upload(text, student)).status, 403);
        assert.equal((await upload([['bad.exe', 'application/octet-stream', 'invalid']])).status, 400);
        assert.equal((await upload(Array.from({ length: 11 }, () => text[0]))).status, 400);
        assert.equal((await upload([['large.txt', 'text/plain', Buffer.alloc(25 * 1024 * 1024 + 1)]])).status, 413);
        assert.equal((await upload([['large.png', 'image/png', Buffer.alloc(5 * 1024 * 1024 + 1)]])).status, 400);
        const privateFile = await fetch(`${API}/uploads/assignments/not-present`);
        assert.equal(privateFile.headers.get('cross-origin-resource-policy'), 'same-origin');
        const files = await Promise.all([
            ['practice-checklist.pdf', 'application/pdf'], ['learning-routine.png', 'image/png'], ['practice-notes.txt', 'text/plain']
        ].map(async ([name, type]) => [name, type, await fs.readFile(path.join(fixtures, name))]));
        const uploaded = await upload(files);
        assert.equal(uploaded.status, 201);
        attached = (await uploaded.json()).video.downloads;
        assert.equal(attached.length, 3);
        for (const item of attached) {
            const response = await fetch(new URL(item.url, API));
            assert.equal(response.status, 200);
            assert.equal(response.headers.get('cross-origin-resource-policy'), 'cross-origin');
            assert.ok((await response.arrayBuffer()).byteLength > 0);
        }
        const update = await fetch(`${base}/content`, { method: 'PUT', headers, body: JSON.stringify({
            learnText: 'A plain-text learning note.', learnPoints: ['Read', 'Practise'], downloads: attached
        }) });
        assert.equal(update.status, 200);
        const saved = (await update.json()).video;
        assert.equal(saved.learnText, 'A plain-text learning note.');
        assert.deepEqual(saved.downloads.map((item) => item.key), attached.map((item) => item.key));
        const badLink = await fetch(`${base}/content`, { method: 'PUT', headers, body: JSON.stringify({
            downloads: [{ title: 'Unsafe', url: 'javascript:alert(1)' }]
        }) });
        assert.equal(badLink.status, 400);
        const remove = await fetch(`${base}/content`, { method: 'PUT', headers, body: JSON.stringify({ downloads: attached.slice(0, 2) }) });
        assert.equal(remove.status, 200);
        assert.equal((await fetch(new URL(attached[2].url, API))).status, 404);
        const limit = await fetch(`${base}/content`, { method: 'PUT', headers, body: JSON.stringify({ downloads: [
            ...attached.slice(0, 2), ...Array.from({ length: 18 }, (_, i) => ({ title: `Reference ${i}`, url: `https://example.com/${i}.pdf` }))
        ] }) });
        assert.equal(limit.status, 200);
        assert.equal((await upload(text)).status, 400);
        assert.equal((await fetch(`${base}/content`, { method: 'PUT', headers, body: JSON.stringify({ learnText: 'a'.repeat(20001) }) })).status, 400);
    } finally {
        assert.equal((await fetch(base, { method: 'DELETE', headers })).status, 200);
    }
    for (const item of attached) assert.equal((await fetch(new URL(item.url, API))).status, 404);
    console.log('Passed: admin-only upload, file types/count/size, real PDF/image/TXT, plain text, safe links, persistence, removal and cleanup.');
}
main().catch((error) => { console.error(error.message); process.exitCode = 1; });
