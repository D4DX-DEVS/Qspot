const express = require('express');
const mongoose = require('mongoose');
const VideoProgress = require('../models/videoProgress');
const Video = require('../models/videos');
const VideoQuestion = require('../models/videoQuestions');
const VideoQuizAttempt = require('../models/videoQuizAttempt');
const { authenticateUser } = require('../middlewares/auth');
const { recordLearningEvent } = require('../services/learningEvents');

const router = express.Router();

// A single heartbeat may not claim more than this many seconds of new watch
// time. Anything larger is a seek and is ignored — that is what stops a student
// from dragging the scrubber to the end and being marked complete.
const MAX_TICK_SECONDS = 5;

// Watched share of the runtime required to count as complete.
const COMPLETION_RATIO = 0.9;

const shape = (progress, extra = {}) => {
    const completed = Boolean(progress.completed);
    const started = (progress.watchedSeconds || 0) > 0 || (progress.positionSeconds || 0) > 0;
    return {
        videoId: progress.videoId,
        positionSeconds: progress.positionSeconds || 0,
        maxPositionSeconds: progress.maxPositionSeconds || 0,
        watchedSeconds: progress.watchedSeconds || 0,
        durationSeconds: progress.durationSeconds || 0,
        completed,
        completedAt: progress.completedAt || null,
        lastViewedAt: progress.lastViewedAt || null,
        status: completed ? 'completed' : started ? 'in-progress' : 'not-started',
        ...extra
    };
};

const withCounts = async (rows) => {
    const videoIds = rows.map((r) => r.videoId);
    const [questionCounts, quizAttempts] = await Promise.all([
        VideoQuestion.aggregate([
            { $match: { videoId: { $in: videoIds } } },
            { $group: { _id: '$videoId', count: { $sum: 1 } } }
        ]),
        VideoQuizAttempt.find({ videoId: { $in: videoIds }, userId: rows[0]?.userId }).select('videoId')
    ]);
    const qcMap = new Map(questionCounts.map((c) => [String(c._id), c.count]));
    const attemptedSet = new Set(quizAttempts.map((a) => String(a.videoId)));
    return rows.map((row) =>
        shape(row, {
            questionCount: qcMap.get(String(row.videoId)) || 0,
            quizAttempted: attemptedSet.has(String(row.videoId))
        })
    );
};

// GET /api/video-progress - every video this user has touched, with status
router.get('/', authenticateUser, async (req, res) => {
    try {
        const rows = await VideoProgress.find({ userId: req.user.id }).sort({ lastViewedAt: -1 });
        if (rows.length === 0) return res.json([]);
        return res.json(await withCounts(rows));
    } catch (error) {
        console.error('Error fetching video progress:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
});

// GET /api/video-progress/:videoId - one video's status for this user
router.get('/:videoId', authenticateUser, async (req, res) => {
    try {
        const { videoId } = req.params;
        if (!mongoose.Types.ObjectId.isValid(videoId)) {
            return res.status(400).json({ message: 'Invalid videoId' });
        }

        const [questionCount, attempt] = await Promise.all([
            VideoQuestion.countDocuments({ videoId }),
            VideoQuizAttempt.exists({ videoId, userId: req.user.id })
        ]);

        const row = await VideoProgress.findOne({ userId: req.user.id, videoId });
        if (!row) {
            return res.json({
                videoId,
                positionSeconds: 0,
                maxPositionSeconds: 0,
                watchedSeconds: 0,
                durationSeconds: 0,
                completed: false,
                completedAt: null,
                lastViewedAt: null,
                status: 'not-started',
                questionCount,
                quizAttempted: Boolean(attempt)
            });
        }
        return res.json(shape(row, { questionCount, quizAttempted: Boolean(attempt) }));
    } catch (error) {
        console.error('Error fetching video progress:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
});

// POST /api/video-progress - player heartbeat
// body: { videoId, position, watchedDelta, duration? }
router.post('/', authenticateUser, async (req, res) => {
    try {
        const { videoId, position, duration, watchedDelta } = req.body || {};

        if (!videoId || !mongoose.Types.ObjectId.isValid(videoId)) {
            return res.status(400).json({ message: 'Invalid videoId' });
        }

        const video = await Video.findById(videoId).select('_id durationSeconds');
        if (!video) {
            return res.status(404).json({ message: 'Video not found' });
        }

        const positionSeconds = Math.max(0, Number(position) || 0);
        const delta = Number(watchedDelta) || 0;
        const countedSeconds = delta > 0 && delta <= MAX_TICK_SECONDS ? delta : 0;
        const clientDuration = Math.max(0, Number(duration) || 0);

        // The video's own durationSeconds is authoritative once set. Only a
        // client heartbeat may set it the first time (e.g. the video document
        // was created without one), and only when it isn't set yet.
        let effectiveDuration = video.durationSeconds || 0;
        if (effectiveDuration <= 0 && clientDuration > 0) {
            effectiveDuration = clientDuration;
            await Video.updateOne({ _id: videoId, durationSeconds: { $lte: 0 } }, { $set: { durationSeconds: clientDuration } });
        }

        const update = {
            $inc: { watchedSeconds: countedSeconds },
            $max: { maxPositionSeconds: positionSeconds },
            $set: { positionSeconds, lastViewedAt: new Date() },
            $setOnInsert: { userId: req.user.id, videoId }
        };
        if (effectiveDuration > 0) {
            update.$set.durationSeconds = effectiveDuration;
        }

        let progress = await VideoProgress.findOneAndUpdate(
            { userId: req.user.id, videoId },
            update,
            { new: true, upsert: true, setDefaultsOnInsert: true }
        );

        const runtime = progress.durationSeconds || 0;
        const watchedEnough = runtime > 0 && progress.watchedSeconds >= runtime * COMPLETION_RATIO;

        if (!progress.completed && watchedEnough) {
            progress = await VideoProgress.findOneAndUpdate(
                { userId: req.user.id, videoId },
                { $set: { completed: true, completedAt: new Date() } },
                { new: true }
            );
        }

        const wasStarted = (progress.watchedSeconds || 0) > 0 || (progress.positionSeconds || 0) > 0;
        if (wasStarted) {
            await recordLearningEvent({ userId: req.user.id, type: 'video_started', sourceType: 'video', sourceId: videoId });
        }
        if (progress.completed) {
            await recordLearningEvent({ userId: req.user.id, type: 'video_completed', sourceType: 'video', sourceId: videoId, occurredAt: progress.completedAt || new Date() });
        }

        const [questionCount, attempted] = await Promise.all([
            VideoQuestion.countDocuments({ videoId }),
            VideoQuizAttempt.exists({ videoId, userId: req.user.id })
        ]);

        return res.json(shape(progress, { questionCount, quizAttempted: Boolean(attempted) }));
    } catch (error) {
        console.error('Error saving video progress:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
