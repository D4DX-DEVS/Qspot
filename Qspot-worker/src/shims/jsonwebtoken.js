// HS256-only jsonwebtoken replacement. node:crypto gives a synchronous HMAC
// (nodejs_compat), which keeps the existing sync jwt.verify(token, secret) calls working.
const { createHmac, timingSafeEqual } = require('node:crypto');

class JsonWebTokenError extends Error { constructor(m) { super(m); this.name = 'JsonWebTokenError'; } }
class TokenExpiredError extends JsonWebTokenError { constructor(m, expiredAt) { super(m); this.name = 'TokenExpiredError'; this.expiredAt = expiredAt; } }

const b64u = (buf) => Buffer.from(buf).toString('base64url');
const sign_ = (data, secret) => createHmac('sha256', secret).update(data).digest();

const UNITS = { s: 1, m: 60, h: 3600, d: 86400, w: 604800, y: 31536000 };
const toSeconds = (v) => {
    if (typeof v === 'number') return v;
    const m = /^(\d+)\s*([smhdwy])?$/.exec(String(v).trim());
    if (!m) throw new Error('Invalid expiresIn');
    return Number(m[1]) * (m[2] ? UNITS[m[2]] : 1);
};

function sign(payload, secret, options = {}) {
    if (!secret) throw new Error('secretOrPrivateKey must have a value');
    const now = Math.floor(Date.now() / 1000);
    const body = { ...payload, iat: now };
    if (options.expiresIn !== undefined) body.exp = now + toSeconds(options.expiresIn);
    const head = b64u(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
    const data = `${head}.${b64u(JSON.stringify(body))}`;
    return `${data}.${b64u(sign_(data, secret))}`;
}

function verifySync(token, secret) {
    const parts = String(token || '').split('.');
    if (parts.length !== 3) throw new JsonWebTokenError('jwt malformed');
    const [h, p, s] = parts;
    let header;
    try { header = JSON.parse(Buffer.from(h, 'base64url').toString()); } catch { throw new JsonWebTokenError('invalid token'); }
    if (header.alg !== 'HS256') throw new JsonWebTokenError('invalid algorithm');
    const expected = sign_(`${h}.${p}`, secret);
    const given = Buffer.from(s, 'base64url');
    if (given.length !== expected.length || !timingSafeEqual(given, expected)) throw new JsonWebTokenError('invalid signature');
    const payload = JSON.parse(Buffer.from(p, 'base64url').toString());
    if (payload.exp && Math.floor(Date.now() / 1000) >= payload.exp) throw new TokenExpiredError('jwt expired', new Date(payload.exp * 1000));
    return payload;
}

function verify(token, secret, options, cb) {
    if (typeof options === 'function') { cb = options; }
    if (typeof cb === 'function') {
        let out; try { out = verifySync(token, secret); } catch (e) { return cb(e); }
        return cb(null, out);
    }
    return verifySync(token, secret);
}

const decode = (token) => { try { return JSON.parse(Buffer.from(String(token).split('.')[1], 'base64url').toString()); } catch { return null; } };

module.exports = { sign, verify, decode, JsonWebTokenError, TokenExpiredError };
