// End-to-end learner/admin flows against a running Worker (demo seed data).
//   node scripts/flows.mjs [baseUrl]
import fs from 'node:fs';
const B = process.argv[2] || 'http://127.0.0.1:8787';
const vars = Object.fromEntries(fs.readFileSync(new URL('../.dev.vars', import.meta.url), 'utf8').split(/\r?\n/).map((l) => l.match(/^([A-Za-z_]\w*)=(.*)$/)).filter(Boolean).map((m) => [m[1], m[2].replace(/^"|"$/g, '')]));
const call = async (method, path, token, body) => {
    const r = await fetch(B + path, { method, headers: { 'content-type': 'application/json', ...(token ? { authorization: 'Bearer ' + token } : {}) }, body: body ? JSON.stringify(body) : undefined });
    let j; try { j = await r.json(); } catch { j = null; }
    return { status: r.status, body: j };
};
let fails = 0;
const check = (name, ok, detail) => { if (!ok) fails++; console.log(ok ? 'PASS' : 'FAIL', name, ok ? '' : JSON.stringify(detail).slice(0, 300)); };

const a = await call('POST', '/api/admin/login', null, { username: vars.ADMIN_USERNAME, password: vars.ADMIN_PASSWORD });
const A = a.body.token;
const s = await call('POST', '/api/user/login', null, { phone: vars.TEST_LOGIN, name: 'Test Student' });
const S = s.body.token;
check('student login', !!S, s);

for (const p of ['/api/user/me', '/api/user/today', '/api/user/progress', '/api/user/prefs', '/api/user/bookmarks', '/api/user/quiz-attempts', '/api/user/learning-stats', '/api/user/notifications', '/api/user/my-questions']) {
    const r = await call('GET', p, S); check('GET ' + p, r.status === 200, r);
}

// Quizzes: list, open, answer, attempt, duplicate, history
const list = await call('GET', '/api/user-quizzes', S);
check('quiz list', list.status === 200 && Array.isArray(list.body.quizzes || list.body), list);
const quizzes = list.body.quizzes || list.body;
const live = quizzes.find((q) => (q.status || '') === 'live') || quizzes[0];
console.log('  quiz pick:', live && (live.title || live.name), live && live.status, live && live._id);
if (live) {
    const qs = await call('GET', `/api/user-quizzes/${live._id}/questions`, S);
    console.log('  questions:', qs.status, Array.isArray(qs.body.questions) ? qs.body.questions.length : JSON.stringify(qs.body).slice(0, 150));
    if (qs.status === 200 && qs.body.questions?.length) {
        const again = await call('GET', `/api/user-quizzes/${live._id}/questions`, S);
        check('same question set on repeat', JSON.stringify(again.body.questions.map((q) => q._id)) === JSON.stringify(qs.body.questions.map((q) => q._id)));
        const answers = qs.body.questions.map((q) => ({ questionId: q._id, attemptedAnswer: (q.options && q.options[0]) ?? '', duration: 3, status: 'answered' }));
        const att = await call('POST', '/api/quizzes/attempt', S, { quizId: live._id, language: 'English', answers, totalDuration: 9 });
        check('submit attempt', att.status === 201 || att.status === 200, att);
        const dup = await call('POST', '/api/quizzes/attempt', S, { quizId: live._id, language: 'English', answers, totalDuration: 9 });
        check('duplicate attempt -> 409', dup.status === 409, dup);
        const hist = await call('GET', '/api/user/quiz-attempts', S);
        check('attempt in history', hist.status === 200 && JSON.stringify(hist.body).includes(live._id), hist);
        const qd = await call('GET', '/api/quiz-definitions', A);
        check('admin quiz definitions', qd.status === 200, qd);
        const att2 = att.body.attempt || att.body;
        const aid = att2._id || att2.attemptId || att2.id;
        if (aid) { const g = await call('GET', `/api/quizzes/attempt/${aid}`, A); check('admin get attempt', g.status === 200, g); }
        const issue = await call('POST', `/api/certificates/quiz/${live._id}/issue`, A, {});
        console.log('  certificate issue:', issue.status, JSON.stringify(issue.body).slice(0, 160));
        check('certificate issue no 5xx', issue.status < 500, issue);
        const mine = await call('GET', '/api/certificates/mine', S);
        check('certificates mine', mine.status === 200, mine);
    }
}

// Video progress + bookmark + practice
const vids = await call('GET', '/api/videos', S);
const v = (vids.body.videos || vids.body)[0];
if (v) {
    const p1 = await call('POST', '/api/video-progress', S, { videoId: v._id, position: 30, duration: 60, watchedDelta: 10 });
    check('video progress tick', p1.status === 200 || p1.status === 201, p1);
    const p2 = await call('POST', '/api/video-progress', S, { videoId: v._id, position: 60, duration: 60, watchedDelta: 10 });
    check('video progress end', p2.status < 300, p2);
    const g = await call('GET', `/api/video-progress/${v._id}`, S);
    check('video progress read', g.status === 200 && JSON.stringify(g.body).includes('position') || g.status === 200, g);
    const bm = await call('PUT', `/api/user/bookmarks/${v._id}`, S);
    check('bookmark add', bm.status < 300, bm);
    const bl = await call('GET', '/api/user/bookmarks', S);
    check('bookmark listed', bl.status === 200 && JSON.stringify(bl.body).includes(v._id), bl);
    const bd = await call('DELETE', `/api/user/bookmarks/${v._id}`, S);
    check('bookmark remove', bd.status < 300, bd);
    const pq = await call('GET', `/api/user/video-quiz?videoId=${v._id}`, S);
    check('video-quiz list', pq.status === 200, pq);
}

// Assignments: list, submit (text), resubmit (upsert), admin sees + grades
const al = await call('GET', '/api/user/assignments', S);
check('assignment list', al.status === 200, al);
const asg = (al.body.assignments || al.body)[0];
if (asg) {
    const sub = await call('POST', `/api/user/assignments/${asg._id}/submit`, S, { text: 'my answer' });
    console.log('  submit:', sub.status, JSON.stringify(sub.body).slice(0, 140));
    check('assignment submit no 5xx', sub.status < 500, sub);
    if (sub.status === 201) {
        const sub2 = await call('POST', `/api/user/assignments/${asg._id}/submit`, S, { text: 'my better answer' });
        check('assignment resubmit (upsert)', sub2.status === 201, sub2);
        const subs = await call('GET', `/api/admin/assignments/${asg._id}/submissions`, A);
        const rows = subs.body.submissions || subs.body.items || subs.body;
        check('admin sees 1 submission', subs.status === 200 && Array.isArray(rows) && rows.filter((r) => JSON.stringify(r).includes('better')).length === 1, subs);
        const sid = rows[0]?._id;
        if (sid) { const gr = await call('PUT', `/api/admin/assignments/${asg._id}/submissions/${sid}`, A, { grade: 8, feedback: 'good', status: 'graded' }); check('admin grade', gr.status === 200, gr); }
    }
}

// Admin CRUD round trip
const c = await call('POST', '/api/courses', A, { title: 'Flow Course', description: 'x' });
check('create course', c.status === 201 || c.status === 200, c);
const cid = c.body.course?._id || c.body._id;
if (cid) {
    const u = await call('PUT', `/api/courses/${cid}`, A, { title: 'Flow Course 2' });
    check('update course', u.status === 200, u);
    const l = await call('GET', '/api/courses', A);
    check('course listed once, renamed', JSON.stringify(l.body).split('Flow Course 2').length === 2, l.body);
    const d = await call('DELETE', `/api/courses/${cid}`, A);
    check('delete course', d.status === 200, d);
}
const an = await call('GET', '/api/admin/analytics/overview', A); console.log('  analytics overview', an.status);
const gb = await call('GET', '/api/admin/gradebook', A); check('gradebook', gb.status === 200, gb);
console.log(fails ? `\n${fails} FAILED` : '\nall passed');
process.exit(fails ? 1 : 0);
