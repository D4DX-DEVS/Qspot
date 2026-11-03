// Minimal Express-compatible router so the existing route files run on Workers.
// Supports Router(), get/post/put/patch/delete/all/use, path params, async
// handlers (a rejected promise goes to the error handler, like Express 5),
// and the req/res members the app uses. dispatch() turns a Fetch Request into
// a Response.

const METHODS = ['get', 'post', 'put', 'patch', 'delete', 'options', 'head'];

function compilePath(path, end) {
    const keys = [];
    let src = path
        .replace(/[.+^${}()|[\]\\]/g, '\\$&')
        .replace(/\/:(\w+)\?/g, (_, k) => { keys.push(k); return '(?:/([^/]+))?'; })
        .replace(/:(\w+)/g, (_, k) => { keys.push(k); return '([^/]+)'; })
        .replace(/\*/g, '(.*)');
    if (src === '/' && !end) src = '';
    return { keys, regex: new RegExp('^' + src + (end ? '/?$' : '(?=/|$)'), 'i') };
}

function Router() {
    const stack = [];
    const router = (req, res, next) => router.handle(req, res, next);

    const add = (method, path, handlers) => {
        const flat = handlers.flat();
        const { keys, regex } = compilePath(path, true);
        stack.push({ method, regex, keys, handlers: flat, end: true });
        return router;
    };
    for (const m of METHODS) router[m] = (path, ...h) => add(m.toUpperCase(), path, h);
    router.all = (path, ...h) => add('*', path, h);
    router.use = (...args) => {
        const path = typeof args[0] === 'string' ? args.shift() : '/';
        const { keys, regex } = compilePath(path, false);
        stack.push({ method: '*', regex, keys, handlers: args.flat(), end: false });
        return router;
    };

    router.handle = (req, res, done) => {
        let i = 0;
        const baseUrl = req.baseUrl || '';
        const outerParams = req.params || {};
        const restore = () => { req.baseUrl = baseUrl; req.params = outerParams; };
        const next = (err) => {
            if (err === 'route' || err === 'router') err = undefined;
            // skip back to the outer router
            if (i >= stack.length) { restore(); return done(err); }
            const layer = stack[i++];
            if (layer.method !== '*' && layer.method !== req.method && !(layer.method === 'GET' && req.method === 'HEAD')) return next(err);
            const m = layer.regex.exec(req.path.slice(baseUrl.length) || '/');
            if (!m) return next(err);
            const params = { ...outerParams };
            layer.keys.forEach((k, idx) => { if (m[idx + 1] !== undefined) params[k] = decodeURIComponent(m[idx + 1]); });
            req.params = params;
            if (!layer.end) req.baseUrl = baseUrl + m[0];
            let h = 0;
            const run = (e) => {
                if (h >= layer.handlers.length) { req.baseUrl = baseUrl; return next(e); }
                const fn = layer.handlers[h++];
                try {
                    // error handlers have 4 params
                    if (e) { if (fn.length === 4) return Promise.resolve(fn(e, req, res, run)).catch(run); return run(e); }
                    if (fn.length === 4) return run();
                    const out = fn(req, res, run);
                    if (out && typeof out.then === 'function') out.catch(run);
                } catch (thrown) { run(thrown); }
            };
            run(err);
        };
        next();
    };
    return router;
}

const express = () => Router();
express.Router = Router;
express.json = () => (req, res, next) => next();
express.urlencoded = () => (req, res, next) => next();
express.static = () => (req, res, next) => next();

// ---- Fetch <-> req/res --------------------------------------------------------------

function makeRes() {
    const headers = new Headers();
    const finish = [];
    const res = {
        statusCode: 200, locals: {}, headersSent: false, _body: null, _done: null,
        status(n) { res.statusCode = n; return res; },
        set(k, v) { if (typeof k === 'object') Object.entries(k).forEach(([a, b]) => headers.set(a, String(b))); else headers.set(k, String(v)); return res; },
        header(k, v) { return res.set(k, v); },
        setHeader(k, v) { return res.set(k, v); },
        getHeader(k) { return headers.get(k); },
        type(t) { return res.set('Content-Type', t.includes('/') ? t : (t === 'json' ? 'application/json' : 'text/' + t)); },
        on(ev, fn) { if (ev === 'finish' || ev === 'close') finish.push(fn); return res; },
        once(ev, fn) { return res.on(ev, fn); },
        json(obj) { if (!headers.has('content-type')) headers.set('content-type', 'application/json; charset=utf-8'); return end(JSON.stringify(obj)); },
        send(body) {
            if (body !== null && typeof body === 'object' && !(body instanceof Uint8Array) && !(body instanceof ArrayBuffer)) return res.json(body);
            if (typeof body === 'string' && !headers.has('content-type')) headers.set('content-type', 'text/html; charset=utf-8');
            return end(body);
        },
        sendStatus(n) { res.statusCode = n; return end(String(n)); },
        redirect(a, b) { const [code, url] = typeof a === 'number' ? [a, b] : [302, a]; res.statusCode = code; headers.set('location', url); return end(null); },
        end(body) { return end(body === undefined ? null : body); },
        _finish: finish, _headers: headers
    };
    let resolve;
    res._promise = new Promise((r) => { resolve = r; });
    function end(body) {
        if (res.headersSent) return res;
        res.headersSent = true;
        res._body = body;
        resolve();
        return res;
    }
    return res;
}

function parseQuery(searchParams) {
    const q = {};
    for (const [k, v] of searchParams) {
        const key = k.endsWith('[]') ? k.slice(0, -2) : k;
        if (key in q) q[key] = [].concat(q[key], v); else q[key] = k.endsWith('[]') ? [v] : v;
    }
    return q;
}

// app: a Router. onError(err, req, res) is the final error handler.
async function dispatch(app, request, { onError, ip } = {}) {
    const url = new URL(request.url);
    const headers = {};
    request.headers.forEach((v, k) => { headers[k] = v; });
    const ctype = headers['content-type'] || '';
    let body = {};
    if (/application\/json/i.test(ctype)) {
        try { const text = await request.text(); body = text ? JSON.parse(text) : {}; } catch (e) { body = null; }
    } else if (/application\/x-www-form-urlencoded/i.test(ctype)) {
        body = Object.fromEntries(new URLSearchParams(await request.text()));
    }
    const req = {
        method: request.method, path: url.pathname, originalUrl: url.pathname + url.search, url: url.pathname + url.search,
        baseUrl: '', params: {}, query: parseQuery(url.searchParams), headers, body: body || {}, ip: ip || headers['cf-connecting-ip'] || '',
        protocol: url.protocol.replace(':', ''), hostname: url.hostname, _request: request,
        get(name) { return headers[String(name).toLowerCase()]; },
        header(name) { return headers[String(name).toLowerCase()]; }
    };
    req.ips = []; req.get.bind(req);
    const res = makeRes();
    if (body === null) {
        res.status(400).json({ message: 'Invalid JSON body' });
    } else {
        app(req, res, (err) => {
            if (err) return Promise.resolve(onError ? onError(err, req, res) : res.status(500).json({ message: 'Internal server error' }));
            return res.status(404).json({ message: 'Not found' });
        });
        // A handler that threw synchronously/asynchronously ends up in the callback above.
        await Promise.race([res._promise, new Promise((r) => setTimeout(r, 25000))]);
    }
    if (!res.headersSent) { res.status(504).json({ message: 'Request timed out' }); }
    for (const fn of res._finish) { try { await fn(); } catch (e) { console.error('finish hook failed', e); } }
    const status = res.statusCode;
    const nullBody = status === 204 || status === 304 || request.method === 'HEAD' || res._body === null;
    return new Response(nullBody ? null : res._body, { status, headers: res._headers });
}

module.exports = express;
module.exports.dispatch = dispatch;
module.exports.default = express;
