const express = require('express');
const Speaker = require('../models/speakers');
const { authenticateToken } = require('../middlewares/auth');
const { upload, getCdnUrl, deleteFile } = require('../services/cdnStorageService');

const router = express.Router();

// Ensure upload middleware is properly initialized
if (!upload || typeof upload.single !== 'function') {
    console.error('Upload middleware not properly initialized');
    process.exit(1);
}

// Create a wrapper for the upload middleware
const uploadSingle = (req, res, next) => {
    return upload.single('image')(req, res, next);
};

// GET /api/speakers - Get all speakers (public)
router.get('/', async (req, res) => {
    try {
        const speakers = await Speaker.find()
            .collation({ locale: 'en', numericOrdering: true })
            .sort({ order: -1, createdAt: -1 });
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
router.post('/', authenticateToken, uploadSingle, async (req, res) => {
    try {
        const { name, designation, order } = req.body;

        // Check if required fields are provided
        if (!name) {
            return res.status(400).json({ message: 'Speaker name is required' });
        }

        // Check if image file was uploaded
        if (!req.file) {
            return res.status(400).json({ message: 'Speaker image is required' });
        }

        const speaker = new Speaker({
            name,
            designation: designation || '',
            image: getCdnUrl(req.file.key),
            imageKey: req.file.key,
            order: order !== undefined ? order : ''
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
router.put('/:id', authenticateToken, uploadSingle, async (req, res) => {
    try {
        const { name, designation, order } = req.body;
        const oldSpeaker = await Speaker.findById(req.params.id);

        if (!oldSpeaker) {
            return res.status(404).json({ message: 'Speaker not found' });
        }

        // Prepare update data
        const updateData = {
            name: name || oldSpeaker.name,
            designation: designation !== undefined ? designation : oldSpeaker.designation,
            order: order !== undefined ? order : oldSpeaker.order
        };

        // Check if new image file was uploaded
        if (req.file) {
            // Delete old image from CDN if it exists
            if (oldSpeaker.imageKey) {
                try {
                    await deleteFile(oldSpeaker.imageKey);
                } catch (error) {
                    console.warn('Could not delete old image from CDN:', error.message);
                }
            }
            
            // Add new image data to update
            updateData.image = getCdnUrl(req.file.key);
            updateData.imageKey = req.file.key;
        }

        // Update with new data (with or without new image)
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
router.delete('/:id', authenticateToken, async (req, res) => {
    try {
        const speaker = await Speaker.findById(req.params.id);

        if (!speaker) {
            return res.status(404).json({ message: 'Speaker not found' });
        }

        // Delete image from CDN if it exists
        if (speaker.imageKey) {
            try {
                await deleteFile(speaker.imageKey);
            } catch (error) {
                console.warn('Could not delete image from CDN:', error.message);
            }
        }

        // Delete speaker from database
        await Speaker.findByIdAndDelete(req.params.id);

        res.json({
            message: 'Speaker deleted successfully',
            speaker
        });
    } catch (error) {
        console.error('Error deleting speaker:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
