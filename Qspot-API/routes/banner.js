const express = require('express');
const Banner = require('../models/banner');
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

// GET /api/banner - Get all banners (public)
router.get('/', async (req, res) => {
    try {
        const banners = await Banner.find().sort({ createdAt: -1 });
        res.json(banners);
    } catch (error) {
        console.error('Error fetching banners:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/banner/:id - Get single banner (public)
router.get('/:id', async (req, res) => {
    try {
        const banner = await Banner.findById(req.params.id);
        if (!banner) {
            return res.status(404).json({ message: 'Banner not found' });
        }
        res.json(banner);
    } catch (error) {
        console.error('Error fetching banner:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/banner - Create new banner with file upload (admin only)
router.post('/', authenticateToken, uploadSingle, async (req, res) => {
    try {
        // Check if file was uploaded
        if (!req.file) {
            return res.status(400).json({ message: 'Image file is required' });
        }

        const banner = new Banner({
            image: getCdnUrl(req.file.key),
            imageKey: req.file.key
        });

        const savedBanner = await banner.save();
        res.status(201).json({
            message: 'Banner created successfully',
            banner: savedBanner
        });
    } catch (error) {
        console.error('Error creating banner:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/banner/:id - Update banner with file upload (admin only)
router.put('/:id', authenticateToken, uploadSingle, async (req, res) => {
    try {
        const oldBanner = await Banner.findById(req.params.id);

        if (!oldBanner) {
            return res.status(404).json({ message: 'Banner not found' });
        }

        // Check if new file was uploaded
        if (!req.file) {
            return res.status(400).json({ message: 'Image file is required' });
        }

        // Delete old file from CDN if it exists
        if (oldBanner.imageKey) {
            try {
                await deleteFile(oldBanner.imageKey);
            } catch (error) {
                console.warn('Could not delete old file from CDN:', error.message);
            }
        }

        // Update with new file
        const banner = await Banner.findByIdAndUpdate(
            req.params.id,
            {
                image: getCdnUrl(req.file.key),
                imageKey: req.file.key
            },
            { new: true, runValidators: true }
        );

        res.json({
            message: 'Banner updated successfully',
            banner
        });
    } catch (error) {
        console.error('Error updating banner:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/banner/:id - Delete banner and file from CDN (admin only)
router.delete('/:id', authenticateToken, async (req, res) => {
    try {
        const banner = await Banner.findById(req.params.id);

        if (!banner) {
            return res.status(404).json({ message: 'Banner not found' });
        }

        // Delete file from CDN if it exists (only if CDN is configured)
        if (banner.imageKey) {
            try {
                await deleteFile(banner.imageKey);
            } catch (error) {
                console.warn('Could not delete file from CDN:', error.message);
            }
        }

        // Delete banner from database
        await Banner.findByIdAndDelete(req.params.id);

        res.json({
            message: 'Banner deleted successfully',
            banner
        });
    } catch (error) {
        console.error('Error deleting banner:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
