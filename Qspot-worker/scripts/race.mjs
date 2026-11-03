// 20 parallel video-progress ticks of 5s each must add up to 100s (no lost updates).
import fs from 'node:fs';
const B = process.argv[2] || 'http://127.0.0.1:8787';
const vars = Object.fromEntries(fs.readFileSync(new URL('../.dev.vars', import.meta.url), 'utf8').split(/\r?\n/).map((l) => l.match(/^([A-Za-z_]\w*)=(.*)$/)).filter(Boolean).map((m) => [m[1], m[2].replace(/^"|"$/g, '')]));
const j = async (m, p, t, b) => { const r = await fetch(B + p, { method: m, headers: { 'content-type': 'application/json', ...(t ? { authorization: 'Bearer ' + t } : {}) }, body: b ? JSON.stringify(b) : undefined }); return { status: r.status, body: await r.json().catch(() => null) }; };
const S = (await j('POST', '/api/user/login', null, { phone: vars.TEST_LOGIN, name: 'Test Student' })).body.token;
const vids = (await j('GET', '/api/videos', S)).body; const v = (vids.videos || vids)[3];
const before = (await j('GET', `/api/video-progress/${v._id}`, S)).body;
const res = await Promise.all(Array.from({ length: 20 }, () => j('POST', '/api/video-progress', S, { videoId: v._id, position: 10, duration: 600, watchedDelta: 5 })));
const after = (await j('GET', `/api/video-progress/${v._id}`, S)).body;
console.log('statuses', [...new Set(res.map((r) => r.status))], '\nbefore', JSON.stringify(before).slice(0, 200), '\nafter ', JSON.stringify(after).slice(0, 200));
