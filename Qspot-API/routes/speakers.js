const express = require('express');
const Speaker = require('../models/speakers');
const Video = require('../models/videos');
const Schedule = require('../models/schedule');
const Question = require('../models/question');
const { authenticateAdmin } = require('../middlewares/auth');
const { upload, getCdnUrl, deleteFile } = require('../services/cdnStorageService');

const router = express.Router();

const uploadSingle = (req, res, next) => {
    return upload.single('image')(req, res, next);
};

// GET /api/speakers - Get all speakers (public)
router.get('/', async (req, res) => {
    try {
        const speakers = await Speaker.find().sort({ order: -1, createdAt: -1 });
        res.json(speakers);
    } catch (error) {
        console.error('Error fetching speakers:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/speakers/:id - Get single speaker (public)
router.get('/:id', async (req, res) => {
    try {
        const speaker = await Speaker.findById(req.params.id);
        if (!speaker) {
            return res.status(404).json({ message: 'Speaker not found' });
        }
        res.json(speaker);
    } catch (error) {
        console.error('Error fetching speaker:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/speakers - Create new speaker with image upload (admin only)
router.post('/', authenticateAdmin, uploadSingle, async (req, res) => {
    try {
        const { name, designation, order } = req.body || {};

        if (!name) {
            return res.status(400).json({ message: 'Speaker name is required' });
        }

        if (!req.file) {
            return res.status(400).json({ message: 'Speaker image is required' });
        }

        const speaker = new Speaker({
            name,
            designation: designation || '',
            image: getCdnUrl(req.file.key),
            imageKey: req.file.key,
            order: order !== undefined && order !== '' ? Number(order) || 0 : 0
        });

        const savedSpeaker = await speaker.save();
        res.status(201).json({
            message: 'Speaker created successfully',
            speaker: savedSpeaker
        });
    } catch (error) {
        console.error('Error creating speaker:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/speakers/:id - Update speaker with image upload (admin only)
router.put('/:id', authenticateAdmin, uploadSingle, async (req, res) => {
    try {
        const { name, designation, order } = req.body || {};
        const oldSpeaker = await Speaker.findById(req.params.id);

        if (!oldSpeaker) {
            return res.status(404).json({ message: 'Speaker not found' });
        }

        const updateData = {
            name: name || oldSpeaker.name,
            designation: designation !== undefined ? designation : oldSpeaker.designation,
            order: order !== undefined && order !== '' ? Number(order) || 0 : oldSpeaker.order
        };

        if (req.file) {
            if (oldSpeaker.imageKey) {
                try {
                    await deleteFile(oldSpeaker.imageKey);
                } catch (error) {
                    console.warn('Could not delete old image from CDN:', error.message);
                }
            }
            updateData.image = getCdnUrl(req.file.key);
            updateData.imageKey = req.file.key;
        }

        const speaker = await Speaker.findByIdAndUpdate(
            req.params.id,
            updateData,
            { new: true, runValidators: true }
        );

        res.json({
            message: 'Speaker updated successfully',
            speaker
        });
    } catch (error) {
        console.error('Error updating speaker:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/speakers/:id - Delete speaker and image from CDN (admin only)
// 409 if the speaker is referenced by videos, schedules or questions.
router.delete('/:id', authenticateAdmin, async (req, res) => {
    try {
        const speaker = await Speaker.findById(req.params.id);

        if (!speaker) {
            return res.status(404).json({ message: 'Speaker not found' });
        }

        const [videos, schedules, questions] = await Promise.all([
            Video.countDocuments({ speaker: speaker._id }),
            Schedule.countDocuments({ faculty: speaker._id }),
            Question.countDocuments({ faculty: speaker._id })
        ]);

        if (videos > 0 || schedules > 0 || questions > 0) {
            return res.status(409).json({
                message: 'Cannot delete a speaker referenced by videos, schedules, or questions.',
                counts: { videos, schedules, questions }
            });
        }

        if (speaker.imageKey) {
            try {
                await deleteFile(speaker.imageKey);
            } catch (error) {
                console.warn('Could not delete image from CDN:', error.message);
            }
        }

        await Speaker.findByIdAndDelete(req.params.id);

        res.json({
            message: 'Speaker deleted successfully',
            id: speaker._id
        });
    } catch (error) {
        console.error('Error deleting speaker:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
