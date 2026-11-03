const express = require('express');
const mongoose = require('mongoose');
const Notification = require('../models/notification');
const { authenticateAdmin, optionalToken } = require('../middlewares/auth');

const router = express.Router();

// Announcement fields an admin can set: who gets it, what a tap opens and
// when it is sent. Throws a 400 error for anything invalid.
const readAnnouncement = (body, existing = null) => {
    const fail = (message) => Object.assign(new Error(message), { status: 400 });
    const title = body.title !== undefined ? String(body.title).trim() : existing?.title;
    const description = body.description !== undefined ? String(body.description).trim() : existing?.description;
    if (!title) throw fail('Notification title is required');
    if (!description) throw fail('Notification description is required');

    const audience = body.audience ?? existing?.audience ?? { kind: 'all', value: '' };
    if (!['all', 'class', 'course'].includes(audience.kind)) throw fail('audience.kind must be all, class or course');
    const audienceValue = String(audience.value || '').trim().slice(0, 80);
    if (audience.kind === 'class' && !audienceValue) throw fail('Pick a class for this notification');
    if (audience.kind === 'course' && !mongoose.Types.ObjectId.isValid(audienceValue)) throw fail('Pick a course for this notification');

    const target = body.target ?? existing?.target ?? { kind: 'none', id: '' };
    if (!['none', 'lesson', 'quiz', 'assignment', 'course'].includes(target.kind)) throw fail('target.kind is invalid');
    const targetId = target.kind === 'none' ? '' : String(target.id || '');
    if (target.kind !== 'none' && !mongoose.Types.ObjectId.isValid(targetId)) throw fail('Pick what this notification opens');

    let sendAt = body.sendAt !== undefined ? body.sendAt : existing?.sendAt ?? null;
    sendAt = sendAt ? new Date(sendAt) : new Date();
    if (Number.isNaN(sendAt.getTime())) throw fail('sendAt must be a valid date');

    return {
        title,
        description,
        audience: { kind: audience.kind, value: audience.kind === 'all' ? '' : audienceValue },
        target: { kind: target.kind, id: targetId },
        sendAt
    };
};

// Announcements everyone may read, for older app versions that still list
// them here: sent, and meant for all learners.
const publicFilter = (now) => ({
    $and: [
        { $or: [{ 'audience.kind': 'all' }, { 'audience.kind': { $exists: false } }] },
        { $or: [{ sendAt: null }, { sendAt: { $lte: now } }] }
    ]
});

// GET /api/notifications - public: announcements for everyone; admin: all.
router.get('/', optionalToken, async (req, res) => {
    try {
        const notifications = await Notification.find(req.isAdmin ? {} : publicFilter(new Date()))
            .sort({ createdAt: -1 });
        res.json(notifications);
    } catch (error) {
        console.error('Error fetching notifications:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/notifications/:id - Get single notification (public)
router.get('/:id', async (req, res) => {
    try {
        const notification = await Notification.findById(req.params.id);
        if (!notification) {
            return res.status(404).json({ message: 'Notification not found' });
        }
        res.json(notification);
    } catch (error) {
        console.error('Error fetching notification:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/notifications - Create (admin). Sent to the audience at sendAt
// (now when not given) by services/notificationJobs.js.
router.post('/', authenticateAdmin, async (req, res) => {
    try {
        const notification = await Notification.create(readAnnouncement(req.body || {}));
        res.status(201).json({
            message: 'Notification created successfully',
            notification
        });
    } catch (error) {
        if (error.status) return res.status(error.status).json({ message: error.message });
        console.error('Error creating notification:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/notifications/:id - Update (admin). Learners keep the copy they
// were sent; once sent, its audience and send time are fixed and nothing is
// sent again.
router.put('/:id', authenticateAdmin, async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) return res.status(400).json({ message: 'Invalid notification id' });
        const existing = await Notification.findById(req.params.id);
        if (!existing) {
            return res.status(404).json({ message: 'Notification not found' });
        }
        const data = readAnnouncement(req.body || {}, existing);
        if (existing.dispatchedAt) {
            // Already sent: who got it and when cannot change.
            delete data.audience;
            delete data.sendAt;
        }
        const notification = await Notification.findByIdAndUpdate(req.params.id, data, { new: true, runValidators: true });
        res.json({
            message: 'Notification updated successfully',
            notification
        });
    } catch (error) {
        if (error.status) return res.status(error.status).json({ message: error.message });
        console.error('Error updating notification:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// (Removed toggle route since isActive is not used)

// DELETE /api/notifications/:id - Delete notification (admin only)
router.delete('/:id', authenticateAdmin, async (req, res) => {
    try {
        const notification = await Notification.findById(req.params.id);

        if (!notification) {
            return res.status(404).json({ message: 'Notification not found' });
        }

        await Notification.findByIdAndDelete(req.params.id);

        res.json({
            message: 'Notification deleted successfully',
            id: notification._id
        });
    } catch (error) {
        console.error('Error deleting notification:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
