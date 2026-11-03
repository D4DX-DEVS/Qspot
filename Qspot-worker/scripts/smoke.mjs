// Hits the main read endpoints of a running Worker as admin and as the demo student.
//   node scripts/smoke.mjs [baseUrl]
import fs from 'node:fs';
const B = process.argv[2] || 'http://127.0.0.1:8787';
const vars = Object.fromEntries(fs.readFileSync(new URL('../.dev.vars', import.meta.url), 'utf8').split(/\r?\n/).map((l) => l.match(/^([A-Za-z_]\w*)=(.*)$/)).filter(Boolean).map((m) => [m[1], m[2].replace(/^"|"$/g, '')]));
const call = async (method, path, token, body) => {
    const r = await fetch(B + path, { method, headers: { 'content-type': 'application/json', ...(token ? { authorization: 'Bearer ' + token } : {}) }, body: body ? JSON.stringify(body) : undefined });
    let j; try { j = await r.json(); } catch { j = null; }
    return { status: r.status, body: j };
};
const admin = await call('POST', '/api/admin/login', null, { username: vars.ADMIN_USERNAME, password: vars.ADMIN_PASSWORD });
const adminToken = admin.body?.token;
const student = await call('POST', '/api/user/login', null, { phone: vars.TEST_LOGIN, name: 'Test Student' });
const studentToken = student.body?.token;
console.log('admin login', admin.status, '| student login', student.status, student.status !== 200 ? JSON.stringify(student.body) : '');
const adminPaths = ['/api/courses', '/api/subjects', '/api/speakers', '/api/videos', '/api/banner', '/api/notifications', '/api/quiz-definitions', '/api/quizzes', '/api/questions', '/api/schedules', '/api/video-questions', '/api/admin/analytics', '/api/admin/gradebook', '/api/admin/assignments', '/api/admin/navigation', '/api/certificates', '/api/admin/users', '/api/navigation', '/api/user-quizzes', '/api/quiz-questions'];
const userPaths = ['/api/user/profile', '/api/user/learning-stats', '/api/user/assignments', '/api/user/notifications', '/api/user-quizzes', '/api/courses', '/api/subjects', '/api/videos', '/api/user/progress', '/api/schedules', '/api/speakers', '/api/banner'];
let bad = 0;
for (const [who, token, paths] of [['admin', adminToken, adminPaths], ['student', studentToken, userPaths]]) {
    for (const p of paths) {
        const r = await call('GET', p, token);
        const flag = r.status >= 500 ? 'FAIL' : r.status >= 400 ? 'warn' : 'ok  ';
        if (r.status >= 500) bad++;
        console.log(flag, who.padEnd(7), r.status, p, r.status >= 400 ? JSON.stringify(r.body).slice(0, 120) : (Array.isArray(r.body) ? `[${r.body.length}]` : ''));
    }
}
process.exit(bad ? 1 : 0);
