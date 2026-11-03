const express = require('express');
const mongoose = require('mongoose');
const User = require('../models/user');
const UserNotification = require('../models/userNotification');
const { authenticateUser } = require('../middlewares/auth');

// The learner's notification inbox. Mounted at /api/user/notifications.
const router = express.Router();

const PAGE_SIZE = 50;
const PLATFORMS = ['android', 'ios', 'web', 'other'];

const shape = (item) => ({
    _id: item._id,
    kind: item.kind,
    title: item.title,
    description: item.body,
    target: item.target || { kind: 'none', id: '' },
    read: Boolean(item.readAt),
    createdAt: item.createdAt
});

// GET /api/user/notifications?before=<ISO date> - newest first, 50 at a time.
router.get('/', authenticateUser, async (req, res) => {
    try {
        const filter = { userId: req.user.id };
        const before = req.query.before ? new Date(req.query.before) : null;
        if (before && !Number.isNaN(before.getTime())) filter.createdAt = { $lt: before };
        const [items, unreadCount] = await Promise.all([
            UserNotification.find(filter).sort({ createdAt: -1 }).limit(PAGE_SIZE).lean(),
            UserNotification.countDocuments({ userId: req.user.id, readAt: null })
        ]);
        res.json({ items: items.map(shape), unreadCount, hasMore: items.length === PAGE_SIZE });
    } catch (error) {
        console.error('Error fetching notifications:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/user/notifications/read-all
router.post('/read-all', authenticateUser, async (req, res) => {
    try {
        const result = await UserNotification.updateMany({ userId: req.user.id, readAt: null }, { $set: { readAt: new Date() } });
        res.json({ updated: result.modifiedCount });
    } catch (error) {
        console.error('Error marking notifications read:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/user/notifications/:id/read
router.post('/:id/read', authenticateUser, async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) return res.status(400).json({ message: 'Invalid notification id' });
        const item = await UserNotification.findOneAndUpdate(
            { _id: req.params.id, userId: req.user.id },
            { $set: { readAt: new Date() } },
            { new: true }
        ).lean();
        if (!item) return res.status(404).json({ message: 'Notification not found' });
        res.json(shape(item));
    } catch (error) {
        console.error('Error marking notification read:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/user/notifications/push-token { token, platform }
// Registers this phone for push. Kept to the 5 most recent phones.
router.put('/push-token', authenticateUser, async (req, res) => {
    try {
        const token = String(req.body?.token || '').trim();
        if (!token || token.length > 4096) return res.status(400).json({ message: 'A valid token is required' });
        const platform = PLATFORMS.includes(req.body?.platform) ? req.body.platform : 'other';
        await User.updateOne({ _id: req.user.id }, { $pull: { pushTokens: { token } } });
        await User.updateOne({ _id: req.user.id }, {
            $push: { pushTokens: { $each: [{ token, platform, updatedAt: new Date() }], $slice: -5 } }
        });
        res.json({ registered: true });
    } catch (error) {
        console.error('Error saving push token:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/user/notifications/push-token { token } - on logout.
router.delete('/push-token', authenticateUser, async (req, res) => {
    try {
        const token = String(req.body?.token || '').trim();
        if (token) await User.updateOne({ _id: req.user.id }, { $pull: { pushTokens: { token } } });
        res.json({ removed: Boolean(token) });
    } catch (error) {
        console.error('Error removing push token:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
