const rateLimit = require('express-rate-limit');

// A class or a date of birth can be guessed, so sign-in must not allow
// unlimited tries.
// Only failed attempts count (status 400 and up), so a class of students
// signing in correctly from one school network never uses the allowance up.
const WINDOW_MS = 15 * 60 * 1000;
const MAX_FAILED_PER_PHONE = 5;
// A whole school can share one internet address, so typos from a classroom
// signing in at the start of a quiz must not lock everyone out. Each number
// keeps its own 5-try limit; this only stops one device guessing across many
// numbers. Adjustable with LOGIN_MAX_FAILED_PER_IP.
const DEFAULT_MAX_FAILED_PER_IP = 300;
const MAX_FAILED_PER_IP = (() => {
    const value = Number.parseInt(process.env.LOGIN_MAX_FAILED_PER_IP, 10);
    return Number.isFinite(value) && value > 0 ? value : DEFAULT_MAX_FAILED_PER_IP;
})();

const failedAttempts = (limit, keyGenerator) => rateLimit({
    windowMs: WINDOW_MS,
    limit,
    skipSuccessfulRequests: true,
    standardHeaders: true,
    legacyHeaders: false,
    ...(keyGenerator ? { keyGenerator } : {}),
    message: { message: 'Too many failed attempts. Please try again in 15 minutes.' }
});

// Same number written differently (+91, spaces, leading 0) shares one allowance.
const phoneKey = (req) => `phone:${String(req.body?.phone || '').replace(/\D/g, '').slice(-10)}`;

// Stops one number's guesses; also what a single guesser hits first.
const loginPhoneLimiter = () => failedAttempts(MAX_FAILED_PER_PHONE, phoneKey);
// Stops one device trying the same date against many numbers.
const loginIpLimiter = () => failedAttempts(MAX_FAILED_PER_IP);

// The admin panel has one login with full control: stop password guessing.
const MAX_FAILED_ADMIN = 5;
const adminLoginLimiter = () => failedAttempts(MAX_FAILED_ADMIN);

module.exports = { loginPhoneLimiter, loginIpLimiter, adminLoginLimiter, phoneKey, MAX_FAILED_PER_PHONE, MAX_FAILED_PER_IP, MAX_FAILED_ADMIN };
