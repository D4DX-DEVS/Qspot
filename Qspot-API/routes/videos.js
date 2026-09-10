const express = require('express');
const Video = require('../models/videos');
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
    return upload.single('video')(req, res, next);
};

// GET /api/videos - Get all videos (public)
router.get('/', async (req, res) => {
    try {
        const videos = await Video.find()
            .populate('subject', 'name')
            .sort({ createdAt: -1 });
        res.json(videos);
    } catch (error) {
        console.error('Error fetching videos:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/videos/:id - Get single video (public)
router.get('/:id', async (req, res) => {
    try {
        const video = await Video.findById(req.params.id).populate('subject', 'name');
        if (!video) {
            return res.status(404).json({ message: 'Video not found' });
        }
        res.json(video);
    } catch (error) {
        console.error('Error fetching video:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});


// POST /api/videos - Create new video with file upload or URL (admin only)
router.post('/', authenticateToken, (req, res, next) => {
    // Check if it's a multipart/form-data request (file upload)
    if (req.headers['content-type'] && req.headers['content-type'].includes('multipart/form-data')) {
        return uploadSingle(req, res, next);
    }
    // Otherwise, it's a JSON request (URL)
    next();
}, async (req, res) => {
    try {
        const { title, description, subject, video, releaseDate } = req.body;

        // Check if required fields are provided
        if (!title) {
            return res.status(400).json({ message: 'Video title is required' });
        }
        if (!subject) {
            return res.status(400).json({ message: 'Subject is required' });
        }

        let videoData = {
            title,
            description: description || '',
            subject,
            releaseDate: releaseDate || ''
        };

        // Check if it's a file upload or URL
        if (req.file) {
            // File upload case
            videoData.video = getCdnUrl(req.file.key);
            videoData.videoKey = req.file.key;
        } else if (video && typeof video === 'string') {
            // URL case
            videoData.video = video;
            videoData.videoKey = null; // No file key for URLs
        } else {
            return res.status(400).json({ message: 'Video file or URL is required' });
        }

        const newVideo = new Video(videoData);
        const savedVideo = await newVideo.save();
        await savedVideo.populate('subject', 'name');
        
        res.status(201).json({
            message: 'Video created successfully',
            video: savedVideo
        });
    } catch (error) {
        console.error('Error creating video:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/videos/:id - Update video with file upload or URL (admin only)
router.put('/:id', authenticateToken, (req, res, next) => {
    // Check if it's a multipart/form-data request (file upload)
    if (req.headers['content-type'] && req.headers['content-type'].includes('multipart/form-data')) {
        return uploadSingle(req, res, next);
    }
    // Otherwise, it's a JSON request (URL)
    next();
}, async (req, res) => {
    try {
        const { title, description, subject, video, releaseDate } = req.body;
        const oldVideo = await Video.findById(req.params.id);

        if (!oldVideo) {
            return res.status(404).json({ message: 'Video not found' });
        }

        let updateData = {
            title: title || oldVideo.title,
            description: description !== undefined ? description : oldVideo.description,
            subject: subject || oldVideo.subject,
            releaseDate: releaseDate !== undefined ? releaseDate : oldVideo.releaseDate
        };

        // Handle video update
        if (req.file) {
            // New file upload
            // Delete old video from CDN if it exists
            if (oldVideo.videoKey) {
                try {
                    await deleteFile(oldVideo.videoKey);
                } catch (error) {
                    console.warn('Could not delete old video from CDN:', error.message);
                }
            }
            updateData.video = getCdnUrl(req.file.key);
            updateData.videoKey = req.file.key;
        } else if (video && typeof video === 'string') {
            // New URL provided
            // Delete old video from CDN if it exists and was a file
            if (oldVideo.videoKey) {
                try {
                    await deleteFile(oldVideo.videoKey);
                } catch (error) {
                    console.warn('Could not delete old video from CDN:', error.message);
                }
            }
            updateData.video = video;
            updateData.videoKey = null; // No file key for URLs
        }
        // If neither file nor video URL is provided, keep existing video

        const updatedVideo = await Video.findByIdAndUpdate(
            req.params.id,
            updateData,
            { new: true, runValidators: true }
        ).populate('subject', 'name');

        res.json({
            message: 'Video updated successfully',
            video: updatedVideo
        });
    } catch (error) {
        console.error('Error updating video:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/videos/:id - Delete video and file from CDN (admin only)
router.delete('/:id', authenticateToken, async (req, res) => {
    try {
        const video = await Video.findById(req.params.id);

        if (!video) {
            return res.status(404).json({ message: 'Video not found' });
        }

        // Delete video from CDN if it exists
        if (video.videoKey) {
            try {
                await deleteFile(video.videoKey);
            } catch (error) {
                console.warn('Could not delete video from CDN:', error.message);
            }
        }

        // Delete video from database
        await Video.findByIdAndDelete(req.params.id);

        res.json({
            message: 'Video deleted successfully',
            video
        });
    } catch (error) {
        console.error('Error deleting video:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
