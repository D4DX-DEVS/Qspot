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

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        if (decoded.role !== 'student') {
            return res.status(403).json({ message: 'Student access required' });
        }

        // Check if user exists in database
        const user = await User.findById(decoded.userId);
        if (!user || user.role !== 'student') {
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
    } catch (err) {
        return res.status(403).json({ message: 'Invalid or expired token' });
    }
};

const authenticateFaculty = async (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'Access token required' });
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        if (decoded.role !== 'faculty') return res.status(403).json({ message: 'Faculty access required' });
        const user = await User.findById(decoded.userId);
        if (!user || user.role !== 'faculty' || !user.facultyProfile) {
            return res.status(403).json({ message: 'Faculty account is not configured' });
        }
        req.user = { id: user._id.toString(), name: user.name, phone: user.phone, role: 'faculty', facultyProfile: user.facultyProfile.toString() };
        next();
    } catch (err) {
        return res.status(403).json({ message: 'Invalid or expired token' });
    }
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
