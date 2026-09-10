const express = require('express');
const Subject = require('../models/subject');
const { authenticateToken } = require('../middlewares/auth');
const { upload, getCdnUrl, deleteFile } = require('../services/cdnStorageService');

const router = express.Router();

// Ensure upload middleware is properly initialized
if (!upload || typeof upload.single !== 'function') {
    console.error('Upload middleware not properly initialized');
    process.exit(1);
}

// Wrapper to use multer single for 'image'
const uploadSingle = (req, res, next) => {
    return upload.single('image')(req, res, next);
};

// GET /api/subjects - Get all subjects (public)
router.get('/', async (req, res) => {
    try {
        const subjects = await Subject.find().sort({ order: 1, createdAt: -1 });
        res.json(subjects);
    } catch (error) {
        console.error('Error fetching subjects:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/subjects/:id - Get single subject (public)
router.get('/:id', async (req, res) => {
    try {
        const subject = await Subject.findById(req.params.id);
        if (!subject) {
            return res.status(404).json({ message: 'Subject not found' });
        }
        res.json(subject);
    } catch (error) {
        console.error('Error fetching subject:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/subjects - Create new subject with image upload (admin only)
router.post('/', authenticateToken, uploadSingle, async (req, res) => {
    try {
        const { order, name } = req.body;

        if (order === undefined || !name) {
            return res.status(400).json({ message: 'Order and name are required' });
        }

        if (!req.file) {
            return res.status(400).json({ message: 'Image file is required' });
        }

        const subject = new Subject({
            order,
            name,
            image: getCdnUrl(req.file.key),
            imageKey: req.file.key
        });

        const saved = await subject.save();
        res.status(201).json({ message: 'Subject created successfully', subject: saved });
    } catch (error) {
        console.error('Error creating subject:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/subjects/:id - Update subject with new image (admin only)
router.put('/:id', authenticateToken, uploadSingle, async (req, res) => {
    try {
        const { order, name } = req.body;
        const old = await Subject.findById(req.params.id);

        if (!old) {
            return res.status(404).json({ message: 'Subject not found' });
        }

        if (order === undefined || !name) {
            return res.status(400).json({ message: 'Order and name are required' });
        }

        // Delete old image if exists
        if (req.file && old.imageKey) {
            try { await deleteFile(old.imageKey); } catch (e) { console.warn('Could not delete old image:', e.message); }
        }

        const updatePayload = {
            order,
            name
        };

        if (req.file) {
            updatePayload.image = getCdnUrl(req.file.key);
            updatePayload.imageKey = req.file.key;
        }

        const updated = await Subject.findByIdAndUpdate(
            req.params.id,
            updatePayload,
            { new: true, runValidators: true }
        );

        res.json({ message: 'Subject updated successfully', subject: updated });
    } catch (error) {
        console.error('Error updating subject:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/subjects/:id - Delete subject and image (admin only)
router.delete('/:id', authenticateToken, async (req, res) => {
    try {
        const subject = await Subject.findById(req.params.id);
        if (!subject) {
            return res.status(404).json({ message: 'Subject not found' });
        }

        if (subject.imageKey) {
            try { await deleteFile(subject.imageKey); } catch (e) { console.warn('Could not delete image:', e.message); }
        }

        await Subject.findByIdAndDelete(req.params.id);
        res.json({ message: 'Subject deleted successfully', subject });
    } catch (error) {
        console.error('Error deleting subject:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;


