// express-rate-limit replacement backed by D1 so limits hold across isolates.
// Fixed window per key. With skipSuccessfulRequests only responses >= 400 count.
const mongoose = require('./mongoose');

let counter = 0;

function rateLimit(opts = {}) {
    const id = counter++;
    const windowMs = opts.windowMs || 60000;
    const limit = opts.limit ?? opts.max ?? 5;
    const message = opts.message || { message: 'Too many requests, please try again later.' };
    const keyOf = (req) => `${id}:${opts.keyGenerator ? opts.keyGenerator(req) : req.ip}`;
    const db = () => mongoose.__db();

    const read = async (key) => {
        const row = await db().prepare('SELECT count, reset_at FROM rate_limits WHERE key=?').bind(key).first();
        return row && row.reset_at > Date.now() ? row : null;
    };
    const hit = async (key) => {
        const now = Date.now();
        await db().prepare(
            `INSERT INTO rate_limits (key,count,reset_at) VALUES (?,1,?)
             ON CONFLICT(key) DO UPDATE SET count = CASE WHEN reset_at <= ? THEN 1 ELSE count + 1 END,
             reset_at = CASE WHEN reset_at <= ? THEN ? ELSE reset_at END`
        ).bind(key, now + windowMs, now, now, now + windowMs).run();
    };

    return async (req, res, next) => {
        try {
            const key = opts.keyGenerator ? keyOfSafe() : keyOf(req);
            function keyOfSafe() { return keyOf(req); }
            const row = await read(key);
            if (row && row.count >= limit) {
                if (opts.standardHeaders) res.set('Retry-After', String(Math.ceil((row.reset_at - Date.now()) / 1000)));
                return res.status(429).json(message);
            }
            if (opts.skipSuccessfulRequests) res.on('finish', async () => { if (res.statusCode >= 400) await hit(key); });
            else await hit(key);
        } catch (e) {
            console.error('rate limit store error, allowing request:', e.message);
        }
        next();
    };
}

module.exports = rateLimit;
module.exports.default = rateLimit;
module.exports.rateLimit = rateLimit;
