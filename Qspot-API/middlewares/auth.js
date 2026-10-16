const jwt = require('jsonwebtoken');
const User = require('../models/user');

// Verifies the JWT signature AND requires role === 'admin'. Any route guarded
// by this middleware is admin-only; a valid student token is rejected with 403.
const authenticateAdmin = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
        return res.status(401).json({ message: 'Access token required' });
    }

    jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
        if (err) {
            return res.status(403).json({ message: 'Invalid or expired token' });
        }
        if (!decoded || decoded.role !== 'admin') {
            return res.status(403).json({ message: 'Admin access required' });
        }
        req.user = decoded;
        next();
    });
};

const authenticateUser = async (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
        return res.status(401).json({ message: 'Access token required' });
    }

    let decoded;
    try {
        decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
        return res.status(403).json({ message: 'Invalid or expired token' });
    }

    if (decoded.role !== 'student') {
        return res.status(403).json({ message: 'Student access required' });
    }

    // Check if user exists in database. Runs on every student request, so
    // fetch only the fields used below as a plain object: the full document
    // carries up to 500 learning events and is rebuilt as a Mongoose
    // document each time, which adds up when a whole class signs in at once.
    let user;
    try {
        user = await User.findById(decoded.userId)
            .select('name phone email class role facultyProfile')
            .lean();
    } catch (err) {
        return databaseTrouble(err, res);
    }
    // A plain object skips schema defaults, so a stored user with no role
    // field is still a student, as it was when this loaded a full document.
    if (!user || (user.role || 'student') !== 'student') {
        return res.status(401).json({ message: 'User not found' });
    }

    // Add user info to request
    req.user = {
        id: user._id.toString(),
        name: user.name,
        phone: user.phone,
        email: user.email,
        class: user.class,
        role: user.role || 'student',
        facultyProfile: user.facultyProfile ? user.facultyProfile.toString() : null
    };

    next();
};

// A database that is slow or busy (e.g. a whole class submitting at once) is
// not a bad sign-in: answer "try again" so the app keeps the learner signed in
// and re-sends. Only an id that cannot exist is treated as a bad token.
const databaseTrouble = (err, res) => {
    if (err && err.name === 'CastError') {
        return res.status(403).json({ message: 'Invalid or expired token' });
    }
    console.error('Sign-in check could not reach the database:', err && err.message);
    return res.status(503).json({ message: 'The server is busy. Please try again in a moment.' });
};

const authenticateFaculty = async (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'Access token required' });
    let decoded;
    try {
        decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
        return res.status(403).json({ message: 'Invalid or expired token' });
    }
    if (decoded.role !== 'faculty') return res.status(403).json({ message: 'Faculty access required' });
    let user;
    try {
        user = await User.findById(decoded.userId);
    } catch (err) {
        return databaseTrouble(err, res);
    }
    if (!user || user.role !== 'faculty' || !user.facultyProfile) {
        return res.status(403).json({ message: 'Faculty account is not configured' });
    }
    req.user = { id: user._id.toString(), name: user.name, phone: user.phone, role: 'faculty', facultyProfile: user.facultyProfile.toString() };
    next();
};

// Attaches req.user when a valid token is present but never rejects the
// request. Used by endpoints that serve a public payload to the mobile app and
// a richer, admin-only payload to the admin panel from the same URL.
const optionalToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        req.isAdmin = false;
        return next();
    }

    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (!err) {
            req.user = user;
        }
        req.isAdmin = Boolean(req.user && req.user.role === 'admin');
        next();
    });
};

// Kept as an alias so any route file that still imports authenticateToken
// keeps admin-only behaviour.
const authenticateToken = authenticateAdmin;

module.exports = { authenticateAdmin, authenticateToken, authenticateUser, authenticateFaculty, optionalToken };
