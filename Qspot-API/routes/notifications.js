const express = require('express');
const Notification = require('../models/notification');
const { authenticateAdmin } = require('../middlewares/auth');

const router = express.Router();

// GET /api/notifications - Get all notifications (public)
router.get('/', async (req, res) => {
    try {
        const notifications = await Notification.find()
            .sort({ createdAt: -1 });
        res.json(notifications);
    } catch (error) {
        console.error('Error fetching notifications:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// (Removed '/all' admin route since isActive is not used)

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

// POST /api/notifications - Create new notification (admin only)
router.post('/', authenticateAdmin, async (req, res) => {
    try {
        const { title, description } = req.body;

        // Check if required fields are provided
        if (!title) {
            return res.status(400).json({ message: 'Notification title is required' });
        }
        if (!description) {
            return res.status(400).json({ message: 'Notification description is required' });
        }

        const notification = new Notification({
            title,
            description
        });

        const savedNotification = await notification.save();
        res.status(201).json({
            message: 'Notification created successfully',
            notification: savedNotification
        });
    } catch (error) {
        console.error('Error creating notification:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/notifications/:id - Update notification (admin only)
router.put('/:id', authenticateAdmin, async (req, res) => {
    try {
        const { title, description } = req.body;
        const oldNotification = await Notification.findById(req.params.id);

        if (!oldNotification) {
            return res.status(404).json({ message: 'Notification not found' });
        }

        const notification = await Notification.findByIdAndUpdate(
            req.params.id,
            {
                title: title || oldNotification.title,
                description: description !== undefined ? description : oldNotification.description,
                
            },
            { new: true, runValidators: true }
        );

        res.json({
            message: 'Notification updated successfully',
            notification
        });
    } catch (error) {
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
