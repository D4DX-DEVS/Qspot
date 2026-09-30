const express = require('express');
const mongoose = require('mongoose');
const Subject = require('../models/subject');
const User = require('../models/user');
const Video = require('../models/videos');
const { authenticateAdmin, optionalToken } = require('../middlewares/auth');
const { upload, getCdnUrl, deleteFile } = require('../services/cdnStorageService');

const router = express.Router();

const uploadSingle = (req, res, next) => upload.single('image')(req, res, next);

const readBool = (value, fallback) => {
    if (value === undefined) return fallback;
    if (typeof value === 'boolean') return value;
    return String(value) !== 'false';
};

// GET /api/subjects?course=<id> - public: published only; admin: all
router.get('/', optionalToken, async (req, res) => {
    try {
        const filter = {};
        if (req.query.course && mongoose.Types.ObjectId.isValid(req.query.course)) {
            filter.courseId = req.query.course;
        }
        // Missing flag means "published" (the schema default), so only an
        // explicit false hides a subject.
        if (!req.isAdmin) filter.isPublished = { $ne: false };
        if (!req.isAdmin && req.user?.userId) {
            const user = await User.findById(req.user.userId).select('courseIds');
            if (user?.courseIds?.length) filter.courseId = { $in: user.courseIds };
        }

        const subjects = await Subject.find(filter).sort({ order: 1, createdAt: -1 });
        res.json(subjects);
    } catch (error) {
        console.error('Error fetching subjects:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/subjects/:id - public: only if published; admin: always
router.get('/:id', optionalToken, async (req, res) => {
    try {
        const subject = await Subject.findById(req.params.id);
        if (!subject || (!req.isAdmin && subject.isPublished === false)) {
            return res.status(404).json({ message: 'Subject not found' });
        }
        res.json(subject);
    } catch (error) {
        console.error('Error fetching subject:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/subjects - Create new subject with image upload (admin only)
router.post('/', authenticateAdmin, uploadSingle, async (req, res) => {
    try {
        const { order, name, courseId, isPublished } = req.body || {};

        if (order === undefined || !name) {
            return res.status(400).json({ message: 'Order and name are required' });
        }

        if (!req.file) {
            return res.status(400).json({ message: 'Image file is required' });
        }

        if (courseId && !mongoose.Types.ObjectId.isValid(courseId)) {
            return res.status(400).json({ message: 'Invalid courseId' });
        }

        const subject = new Subject({
            order,
            name,
            image: getCdnUrl(req.file.key),
            imageKey: req.file.key,
            courseId: courseId || null,
            isPublished: readBool(isPublished, true)
        });

        const saved = await subject.save();
        res.status(201).json({ message: 'Subject created successfully', subject: saved });
    } catch (error) {
        console.error('Error creating subject:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/subjects/:id - Update subject with new image (admin only)
router.put('/:id', authenticateAdmin, uploadSingle, async (req, res) => {
    try {
        const { order, name, courseId, isPublished } = req.body || {};
        const old = await Subject.findById(req.params.id);

        if (!old) {
            return res.status(404).json({ message: 'Subject not found' });
        }

        if (order === undefined || !name) {
            return res.status(400).json({ message: 'Order and name are required' });
        }

        if (courseId !== undefined && courseId !== '' && !mongoose.Types.ObjectId.isValid(courseId)) {
            return res.status(400).json({ message: 'Invalid courseId' });
        }

        const updatePayload = { order, name };
        if (courseId !== undefined) updatePayload.courseId = courseId || null;
        if (isPublished !== undefined) updatePayload.isPublished = readBool(isPublished, old.isPublished);

        if (req.file) {
            updatePayload.image = getCdnUrl(req.file.key);
            updatePayload.imageKey = req.file.key;
        }

        const updated = await Subject.findByIdAndUpdate(
            req.params.id,
            updatePayload,
            { new: true, runValidators: true }
        );

        // Only delete the old image after the update succeeded, so a failed
        // save never leaves the subject pointing at a deleted file.
        if (req.file && old.imageKey && old.imageKey !== req.file.key) {
            try { await deleteFile(old.imageKey); } catch (e) { console.warn('Could not delete old image:', e.message); }
        }

        res.json({ message: 'Subject updated successfully', subject: updated });
    } catch (error) {
        console.error('Error updating subject:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/subjects/:id/guide - Update the first-open guide (admin only)
router.put('/:id/guide', authenticateAdmin, async (req, res) => {
    try {
        const { guideTitle, guidePoints } = req.body || {};

        const subject = await Subject.findById(req.params.id);
        if (!subject) {
            return res.status(404).json({ message: 'Subject not found' });
        }

        if (guideTitle !== undefined) {
            subject.guideTitle = String(guideTitle).trim();
        }

        if (guidePoints !== undefined) {
            if (!Array.isArray(guidePoints)) {
                return res.status(400).json({ message: 'guidePoints must be an array' });
            }
            subject.guidePoints = guidePoints
                .map((point) => ({
                    icon: String(point?.icon || 'info').trim(),
                    text: String(point?.text || '').trim()
                }))
                .filter((point) => point.text.length > 0);
        }

        const saved = await subject.save();
        res.json({ message: 'Guide updated successfully', subject: saved });
    } catch (error) {
        console.error('Error updating subject guide:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/subjects/:id - Delete subject and image (admin only); 409 if videos exist
router.delete('/:id', authenticateAdmin, async (req, res) => {
    try {
        const subject = await Subject.findById(req.params.id);
        if (!subject) {
            return res.status(404).json({ message: 'Subject not found' });
        }

        const videoCount = await Video.countDocuments({ subject: subject._id });
        if (videoCount > 0) {
            return res.status(409).json({
                message: 'Cannot delete a subject that has videos. Move or delete them first.',
                counts: { videos: videoCount }
            });
        }

        if (subject.imageKey) {
            try { await deleteFile(subject.imageKey); } catch (e) { console.warn('Could not delete image:', e.message); }
        }

        await Subject.findByIdAndDelete(req.params.id);
        res.json({ message: 'Subject deleted successfully', id: subject._id });
    } catch (error) {
        console.error('Error deleting subject:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
