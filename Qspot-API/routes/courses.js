const express = require('express');
const mongoose = require('mongoose');
const Course = require('../models/course');
const User = require('../models/user');
const Subject = require('../models/subject');
const Video = require('../models/videos');
const { authenticateAdmin, optionalToken } = require('../middlewares/auth');
const { upload, getCdnUrl, deleteFile } = require('../services/cdnStorageService');

const router = express.Router();

const readPoints = (value) => {
    let list = value;
    if (typeof list === 'string') {
        try {
            list = JSON.parse(list);
        } catch {
            list = list.split('\n');
        }
    }
    if (!Array.isArray(list)) return [];
    return list.map((point) => String(point || '').trim()).filter(Boolean);
};

const readBool = (value, fallback) => {
    if (value === undefined) return fallback;
    if (typeof value === 'boolean') return value;
    return String(value) !== 'false';
};

const uploadCoverIfMultipart = (req, res, next) => {
    const contentType = req.headers['content-type'] || '';
    if (!contentType.includes('multipart/form-data')) {
        return next();
    }
    return upload.single('image')(req, res, next);
};

// GET /api/courses - public: active only; admin: all (optionalToken)
router.get('/', optionalToken, async (req, res) => {
    try {
        const filter = req.isAdmin ? {} : { isActive: true };
        if (!req.isAdmin && req.user?.userId && req.query.forSelection !== 'true') {
            const user = await User.findById(req.user.userId).select('courseIds');
            if (user?.courseIds?.length) filter._id = { $in: user.courseIds };
        }
        const courses = await Course.find(filter).sort({ isActive: -1, order: 1, createdAt: 1 });
        res.json(courses);
    } catch (error) {
        console.error('Error fetching courses:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/courses/:id - course + subjects (with videoCount)
router.get('/:id', optionalToken, async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: 'Invalid course id' });
        }
        const course = await Course.findById(req.params.id);
        if (!course) {
            return res.status(404).json({ message: 'Course not found' });
        }

        const subjectFilter = { courseId: course._id };
        // Subjects predating the flag have no isPublished field and stay
        // visible; only an explicit false hides them.
        if (!req.isAdmin) subjectFilter.isPublished = { $ne: false };

        const subjects = await Subject.find(subjectFilter).sort({ order: 1 });
        const counts = await Video.aggregate([
            { $match: { subject: { $in: subjects.map((s) => s._id) } } },
            { $group: { _id: '$subject', count: { $sum: 1 } } }
        ]);
        const countMap = new Map(counts.map((c) => [String(c._id), c.count]));

        const subjectsWithCount = subjects.map((s) => ({
            ...s.toObject(),
            videoCount: countMap.get(String(s._id)) || 0
        }));

        res.json({ ...course.toObject(), subjects: subjectsWithCount });
    } catch (error) {
        console.error('Error fetching course:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/courses - create (admin)
router.post('/', authenticateAdmin, uploadCoverIfMultipart, async (req, res) => {
    try {
        const { title, subtitle, description, learnPoints, image, order, isActive } = req.body || {};
        if (!title || !String(title).trim()) {
            return res.status(400).json({ message: 'title is required' });
        }

        const course = await Course.create({
            title: String(title).trim(),
            subtitle: String(subtitle || '').trim(),
            description: String(description || '').trim(),
            learnPoints: readPoints(learnPoints),
            image: req.file ? getCdnUrl(req.file.key) : String(image || '').trim(),
            imageKey: req.file ? req.file.key : null,
            order: Number(order) || 0,
            isActive: readBool(isActive, true)
        });

        res.status(201).json({ message: 'Course created successfully', course });
    } catch (error) {
        console.error('Error creating course:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/courses/:id - update (admin)
router.put('/:id', authenticateAdmin, uploadCoverIfMultipart, async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: 'Invalid course id' });
        }

        const existing = await Course.findById(req.params.id);
        if (!existing) {
            return res.status(404).json({ message: 'Course not found' });
        }

        const { title, subtitle, description, learnPoints, image, order, isActive } = req.body || {};
        const update = {};
        if (title !== undefined) update.title = String(title).trim();
        if (subtitle !== undefined) update.subtitle = String(subtitle).trim();
        if (description !== undefined) update.description = String(description).trim();
        if (learnPoints !== undefined) update.learnPoints = readPoints(learnPoints);

        if (req.file) {
            update.image = getCdnUrl(req.file.key);
            update.imageKey = req.file.key;
            if (existing.imageKey && existing.imageKey !== req.file.key) {
                try {
                    await deleteFile(existing.imageKey);
                } catch (error) {
                    console.warn('Could not delete previous course cover:', error.message);
                }
            }
        } else if (image !== undefined) {
            update.image = String(image).trim();
            if (existing.imageKey && update.image !== existing.image) {
                try {
                    await deleteFile(existing.imageKey);
                } catch (error) {
                    console.warn('Could not delete previous course cover:', error.message);
                }
                update.imageKey = null;
            }
        }

        if (order !== undefined) update.order = Number(order) || 0;
        if (isActive !== undefined) update.isActive = readBool(isActive, true);

        const course = await Course.findByIdAndUpdate(req.params.id, update, { new: true });
        if (!course) {
            return res.status(404).json({ message: 'Course not found' });
        }

        res.json({ message: 'Course updated successfully', course });
    } catch (error) {
        console.error('Error updating course:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/courses/:id (admin) - 409 if subjects reference it
router.delete('/:id', authenticateAdmin, async (req, res) => {
    try {
        const course = await Course.findById(req.params.id);
        if (!course) {
            return res.status(404).json({ message: 'Course not found' });
        }

        const subjectCount = await Subject.countDocuments({ courseId: course._id });
        if (subjectCount > 0) {
            return res.status(409).json({
                message: 'Cannot delete a course that has subjects. Move or delete them first.',
                counts: { subjects: subjectCount }
            });
        }

        await Course.findByIdAndDelete(req.params.id);

        if (course.imageKey) {
            try {
                await deleteFile(course.imageKey);
            } catch (error) {
                console.warn('Could not delete course cover from CDN:', error.message);
            }
        }

        res.json({ message: 'Course deleted successfully', id: course._id });
    } catch (error) {
        console.error('Error deleting course:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
