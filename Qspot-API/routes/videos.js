const express = require('express');
const path = require('path');
const mongoose = require('mongoose');
const Video = require('../models/videos');
const VideoQuestion = require('../models/videoQuestions');
const VideoProgress = require('../models/videoProgress');
const VideoQuizAttempt = require('../models/videoQuizAttempt');
const { authenticateAdmin, optionalToken } = require('../middlewares/auth');
const {
    handoutUpload,
    uploadVideo,
    getCdnUrl,
    deleteFile
} = require('../services/cdnStorageService');

const router = express.Router();
const MAX_MATERIALS = 20;

const uploadSingleVideo = (req, res, next) => uploadVideo.single('video')(req, res, next);

// Handout uploads: several files in one request, each optionally titled.
const uploadHandouts = (req, res, next) => {
    const middleware = handoutUpload.array('files', 10);
    return middleware(req, res, next);
};

const readBool = (value, fallback) => {
    if (value === undefined) return fallback;
    if (typeof value === 'boolean') return value;
    return String(value) !== 'false';
};

const isUpcoming = (releaseDate) => {
    if (!releaseDate) return false;
    const parsed = new Date(releaseDate);
    if (Number.isNaN(parsed.getTime())) return false;
    return parsed.getTime() > Date.now();
};

const normalizePracticeTimerMode = (value) =>
    ['none', 'overall', 'per-question', 'both'].includes(value) ? value : 'none';
const normalizePracticeConfig = (body, existing = {}) => {
    const mode = normalizePracticeTimerMode(body.practiceTimerMode ?? existing.practiceTimerMode);
    const overall = body.practiceOverallTimeLimit !== undefined
        ? Number(body.practiceOverallTimeLimit) || null
        : existing.practiceOverallTimeLimit ?? null;
    const perQuestion = body.practicePerQuestionTimeLimit !== undefined
        ? Number(body.practicePerQuestionTimeLimit) || null
        : existing.practicePerQuestionTimeLimit ?? null;
    if ((mode === 'overall' || mode === 'both') && !(overall > 0)) throw new Error('Overall practice timer is required for this timer mode');
    if ((mode === 'per-question' || mode === 'both') && !(perQuestion > 0)) throw new Error('Per-question practice timer is required for this timer mode');
    return {
        practiceEnabled: body.practiceEnabled !== undefined ? readBool(body.practiceEnabled, true) : existing.practiceEnabled !== false,
        practiceTimerMode: mode,
        practiceOverallTimeLimit: overall,
        practicePerQuestionTimeLimit: perQuestion,
        practiceStartDate: body.practiceStartDate !== undefined && body.practiceStartDate !== '' ? new Date(body.practiceStartDate) : (existing.practiceStartDate || null),
        practiceEndDate: body.practiceEndDate !== undefined && body.practiceEndDate !== '' ? new Date(body.practiceEndDate) : (existing.practiceEndDate || null),
        practiceConditions: body.practiceConditions && typeof body.practiceConditions === 'object' ? body.practiceConditions : (existing.practiceConditions || {})
    };
};

// Shapes one video for the response. Admin gets everything; public gets the
// video URL withheld for not-yet-released episodes.
const shapeVideo = (video, questionCount, isAdmin) => {
    const obj = video.toObject ? video.toObject() : { ...video };
    const upcoming = isUpcoming(obj.releaseDate);

    if (!isAdmin && upcoming) {
        obj.video = '';
    }

    return {
        ...obj,
        isUpcoming: upcoming,
        questionCount: questionCount || 0
    };
};

const attachQuestionCounts = async (videos) => {
    const ids = videos.map((v) => v._id);
    const counts = await VideoQuestion.aggregate([
        { $match: { videoId: { $in: ids } } },
        { $group: { _id: '$videoId', count: { $sum: 1 } } }
    ]);
    return new Map(counts.map((c) => [String(c._id), c.count]));
};

// GET /api/videos?subject=&speaker= (optionalToken)
router.get('/', optionalToken, async (req, res) => {
    try {
        const filter = {};
        if (req.query.speaker && mongoose.Types.ObjectId.isValid(req.query.speaker)) {
            filter.speaker = req.query.speaker;
        }
        if (req.query.subject && mongoose.Types.ObjectId.isValid(req.query.subject)) {
            filter.subject = req.query.subject;
        }
        // Docs created before the flag existed have no isPublished field, and
        // they are meant to stay visible (the schema default is true).
        if (!req.isAdmin) filter.isPublished = { $ne: false };

        const videos = await Video.find(filter)
            .populate('subject', '_id name')
            .populate('speaker', '_id name designation image')
            .sort({ subject: 1, order: 1, releaseDate: -1 });

        const countMap = await attachQuestionCounts(videos);
        res.json(videos.map((v) => shapeVideo(v, countMap.get(String(v._id)), req.isAdmin)));
    } catch (error) {
        console.error('Error fetching videos:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/videos/:id (optionalToken)
router.get('/:id', optionalToken, async (req, res) => {
    try {
        const filter = { _id: req.params.id };
        if (!req.isAdmin) filter.isPublished = { $ne: false };

        const video = await Video.findOne(filter)
            .populate('subject', '_id name')
            .populate('speaker', '_id name designation image');
        if (!video) {
            return res.status(404).json({ message: 'Video not found' });
        }
        const questionCount = await VideoQuestion.countDocuments({ videoId: video._id });
        res.json(shapeVideo(video, questionCount, req.isAdmin));
    } catch (error) {
        console.error('Error fetching video:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/videos - Create new video with file upload or URL (admin only)
router.post('/', authenticateAdmin, (req, res, next) => {
    if (req.headers['content-type'] && req.headers['content-type'].includes('multipart/form-data')) {
        return uploadSingleVideo(req, res, next);
    }
    next();
}, async (req, res) => {
    try {
        const { title, description, subject, speaker, video, releaseDate, order, isPublished, durationSeconds } = req.body || {};

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
            releaseDate: releaseDate || '',
            order: order !== undefined ? Number(order) || 0 : 0,
            isPublished: readBool(isPublished, true),
            durationSeconds: durationSeconds !== undefined ? Number(durationSeconds) || 0 : 0
        };
        Object.assign(videoData, normalizePracticeConfig(req.body || {}));

        if (speaker && mongoose.Types.ObjectId.isValid(speaker)) {
            videoData.speaker = speaker;
        }

        if (req.file) {
            videoData.video = getCdnUrl(req.file.key);
            videoData.videoKey = req.file.key;
        } else if (video && typeof video === 'string') {
            videoData.video = video;
            videoData.videoKey = null;
        } else {
            return res.status(400).json({ message: 'Video file or URL is required' });
        }

        const newVideo = new Video(videoData);
        const savedVideo = await newVideo.save();
        await savedVideo.populate('subject', '_id name');
        await savedVideo.populate('speaker', '_id name designation image');

        res.status(201).json({
            message: 'Video created successfully',
            video: shapeVideo(savedVideo, 0, true)
        });
    } catch (error) {
        console.error('Error creating video:', error);
        if (error.message && error.message.includes('practice timer')) return res.status(400).json({ message: error.message });
        res.status(500).json({ message: 'Internal server error' });
    }
});

// PUT /api/videos/:id - Update video with file upload or URL (admin only)
router.put('/:id', authenticateAdmin, (req, res, next) => {
    if (req.headers['content-type'] && req.headers['content-type'].includes('multipart/form-data')) {
        return uploadSingleVideo(req, res, next);
    }
    next();
}, async (req, res) => {
    try {
        const { title, description, subject, speaker, video, releaseDate, order, isPublished, durationSeconds } = req.body || {};
        const oldVideo = await Video.findById(req.params.id);

        if (!oldVideo) {
            return res.status(404).json({ message: 'Video not found' });
        }

        let updateData = {
            title: title || oldVideo.title,
            description: description !== undefined ? description : oldVideo.description,
            subject: subject || oldVideo.subject,
            releaseDate: releaseDate !== undefined ? releaseDate : oldVideo.releaseDate,
            order: order !== undefined ? Number(order) || 0 : oldVideo.order,
            isPublished: isPublished !== undefined ? readBool(isPublished, oldVideo.isPublished) : oldVideo.isPublished,
            durationSeconds: durationSeconds !== undefined ? Number(durationSeconds) || 0 : oldVideo.durationSeconds
        };
        Object.assign(updateData, normalizePracticeConfig(req.body || {}, oldVideo));

        if (speaker !== undefined) {
            updateData.speaker =
                speaker && mongoose.Types.ObjectId.isValid(speaker) ? speaker : null;
        }

        if (req.file) {
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
            if (oldVideo.videoKey) {
                try {
                    await deleteFile(oldVideo.videoKey);
                } catch (error) {
                    console.warn('Could not delete old video from CDN:', error.message);
                }
            }
            updateData.video = video;
            updateData.videoKey = null;
        }

        const updatedVideo = await Video.findByIdAndUpdate(
            req.params.id,
            updateData,
            { new: true, runValidators: true }
        ).populate('subject', '_id name').populate('speaker', '_id name designation image');

        const questionCount = await VideoQuestion.countDocuments({ videoId: updatedVideo._id });
        res.json({
            message: 'Video updated successfully',
            video: shapeVideo(updatedVideo, questionCount, true)
        });
    } catch (error) {
        console.error('Error updating video:', error);
        if (error.message && error.message.includes('practice timer')) return res.status(400).json({ message: error.message });
        res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/videos/:id/files - Upload handout files and append to downloads (admin only)
router.post('/:id/files', authenticateAdmin, async (req, res, next) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(400).json({ message: 'Choose a valid lesson before uploading files.' });
        }
        req.handoutVideo = await Video.findById(req.params.id);
        if (!req.handoutVideo) return res.status(404).json({ message: 'This lesson is no longer available.' });
        if (req.handoutVideo.downloads.length >= MAX_MATERIALS) {
            return res.status(400).json({ message: 'A lesson can have up to 20 learning materials. Remove a file before adding more.' });
        }
        next();
    } catch (error) { next(error); }
}, uploadHandouts, async (req, res) => {
    try {
        const video = req.handoutVideo;

        const files = Array.isArray(req.files) ? req.files : [];
        if (files.length === 0) {
            return res.status(400).json({ message: 'No files were uploaded' });
        }
        if (files.some((file) => file.mimetype.startsWith('image/') && file.size > 5 * 1024 * 1024)) {
            await Promise.allSettled(files.map((file) => deleteFile(file.key || `local:handouts/${file.filename}`)));
            return res.status(400).json({ message: 'Images must be 5 MB or smaller. Resize the image and try again.' });
        }

        let titles = req.body ? req.body.titles : undefined;
        if (typeof titles === 'string') {
            try {
                titles = JSON.parse(titles);
            } catch {
                titles = [titles];
            }
        }
        if (!Array.isArray(titles)) titles = [];

        const uploaded = files.map((file, index) => {
            const originalName = file.originalname || '';
            const fromFileName = path
                .basename(originalName, path.extname(originalName))
                .replace(/[_-]+/g, ' ')
                .trim();
            const provided = String(titles[index] ?? '').trim();

            const key = file.key || `local:handouts/${file.filename}`;
            return {
                title: (provided || fromFileName || 'Handout').slice(0, 160),
                url: getCdnUrl(key),
                key
            };
        });

        // Atomic append prevents simultaneous batches from losing files or
        // exceeding the per-lesson cap.
        const saved = await Video.findOneAndUpdate({
            _id: video._id,
            $expr: { $lte: [{ $size: { $ifNull: ['$downloads', []] } }, MAX_MATERIALS - uploaded.length] }
        }, { $push: { downloads: { $each: uploaded } } }, { new: true, runValidators: true });
        if (!saved) {
            await Promise.allSettled(uploaded.map((file) => deleteFile(file.key)));
            return res.status(400).json({ message: 'A lesson can have up to 20 learning materials. Remove a file before adding more.' });
        }

        res.status(201).json({ message: 'Files uploaded', video: saved });
    } catch (error) {
        await Promise.allSettled((req.files || []).map((file) => deleteFile(file.key || `local:handouts/${file.filename}`)));
        console.error('Error uploading handout files:', error);
        res.status(500).json({ message: 'We couldn’t save these files. Please try uploading them again.' });
    }
});

// PUT /api/videos/:id/content - Learn note, takeaway lines and downloads (admin only)
router.put('/:id/content', authenticateAdmin, async (req, res) => {
    try {
        const { learnText, learnPoints, downloads } = req.body || {};
        let removed = [];

        const video = await Video.findById(req.params.id);
        if (!video) {
            return res.status(404).json({ message: 'Video not found' });
        }

        if (learnText !== undefined) {
            if (typeof learnText !== 'string' || learnText.length > 20000) {
                return res.status(400).json({ message: 'Keep the Learn note within 20,000 characters.' });
            }
            video.learnText = String(learnText).trim();
        }

        if (learnPoints !== undefined) {
            if (!Array.isArray(learnPoints) || learnPoints.length > 30 || learnPoints.some((point) => typeof point !== 'string' || point.length > 500)) {
                return res.status(400).json({ message: 'Add up to 30 key points, each within 500 characters.' });
            }
            video.learnPoints = learnPoints
                .map((point) => String(point || '').trim())
                .filter((point) => point.length > 0);
        }

        if (downloads !== undefined) {
            if (!Array.isArray(downloads) || downloads.length > MAX_MATERIALS) {
                return res.status(400).json({ message: 'A lesson can have up to 20 learning materials.' });
            }
            const nextDownloads = downloads
                .map((item) => ({
                    title: String(item?.title || '').trim(),
                    url: String(item?.url || '').trim(),
                    // Only this lesson's existing uploads may retain a storage key.
                    key: (video.downloads || []).find((stored) => stored.key && stored.url === String(item?.url || '').trim())?.key || null
                }))
                .filter((item) => item.title.length > 0 || item.url.length > 0);

            const validUrl = (url) => {
                if (/^\/uploads\/handouts\/[a-zA-Z0-9][a-zA-Z0-9._-]*$/.test(url)) return true;
                try {
                    const parsed = new URL(url);
                    return ['http:', 'https:'].includes(parsed.protocol) && Boolean(parsed.hostname);
                } catch { return false; }
            };
            if (nextDownloads.some((item) => !item.title || item.title.length > 160 || item.url.length > 2048 || !validUrl(item.url))) {
                return res.status(400).json({ message: 'Give each learning material a title and a valid HTTP or HTTPS file link.' });
            }
            // Delete files only after the revised list is safely persisted.
            const nextKeys = new Set(nextDownloads.map((d) => d.key).filter(Boolean));
            removed = (video.downloads || []).filter((d) => d.key && !nextKeys.has(d.key));

            video.downloads = nextDownloads;
        }

        const saved = await video.save();
        await Promise.allSettled(removed.map((item) => deleteFile(item.key)));
        res.json({ message: 'Video content updated successfully', video: saved });
    } catch (error) {
        console.error('Error updating video content:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// DELETE /api/videos/:id - Delete video, cascade, and clean up CDN files (admin only)
router.delete('/:id', authenticateAdmin, async (req, res) => {
    try {
        const video = await Video.findById(req.params.id);

        if (!video) {
            return res.status(404).json({ message: 'Video not found' });
        }

        if (video.videoKey) {
            try {
                await deleteFile(video.videoKey);
            } catch (error) {
                console.warn('Could not delete video from CDN:', error.message);
            }
        }

        for (const download of video.downloads || []) {
            if (download.key) {
                try {
                    await deleteFile(download.key);
                } catch (error) {
                    console.warn('Could not delete handout from CDN:', error.message);
                }
            }
        }

        await Promise.all([
            VideoQuestion.deleteMany({ videoId: video._id }),
            VideoProgress.deleteMany({ videoId: video._id }),
            VideoQuizAttempt.deleteMany({ videoId: video._id })
        ]);

        await Video.findByIdAndDelete(req.params.id);

        res.json({ message: 'Video deleted successfully', id: video._id });
    } catch (error) {
        console.error('Error deleting video:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
