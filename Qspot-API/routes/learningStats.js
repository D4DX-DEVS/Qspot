const express = require('express');
const User = require('../models/user');
const mongoose = require('mongoose');
const Video = require('../models/videos');
const { authenticateUser } = require('../middlewares/auth');
const { dayKey, recordLearningEvent } = require('../services/learningEvents');

const router = express.Router();
const XP = {
    video_started: 2,
    video_completed: 20,
    video_question_completed: 10,
    quiz_completed: 25,
    assignment_submitted: 15,
    note_read: 5
};

const previousDay = (key) => {
    const date = new Date(`${key}T00:00:00.000Z`);
    date.setUTCDate(date.getUTCDate() - 1);
    return date.toISOString().slice(0, 10);
};

router.get('/', authenticateUser, async (req, res) => {
    try {
        const offset = Number(req.query.tzOffsetMinutes);
        const offsetMinutes = Number.isInteger(offset) && Math.abs(offset) <= 840 ? offset : 0;
        const user = await User.findById(req.user.id).select('learningEvents').lean();
        const events = (user?.learningEvents || []).sort((a, b) => new Date(b.occurredAt) - new Date(a.occurredAt));
        // Recompute day keys at read time so a learner's local midnight is
        // respected even though events are written with a UTC timestamp.
        const days = new Set(events.map((event) => dayKey(event.occurredAt, offsetMinutes)));
        const today = dayKey(new Date(), offsetMinutes);
        const yesterdayDate = new Date(Date.now() - 24 * 60 * 60 * 1000);
        const yesterday = dayKey(yesterdayDate, offsetMinutes);
        const currentStart = days.has(today) ? today : days.has(yesterday) ? yesterday : null;
        let current = 0;
        if (currentStart) {
            let cursor = currentStart;
            while (days.has(cursor)) {
                current += 1;
                cursor = previousDay(cursor);
            }
        }
        let longest = 0;
        for (const eventDay of days) {
            let cursor = eventDay;
            let run = 0;
            while (days.has(cursor)) {
                run += 1;
                cursor = previousDay(cursor);
            }
            longest = Math.max(longest, run);
        }
        const xp = events.reduce((total, event) => total + (XP[event.type] || 0), 0);
        // Grace days need a persisted entitlement/consumption policy; do not
        // infer one from activity history alone.
        const graceDayAvailable = false;
        res.json({ currentStreak: current, longestStreak: longest, xp, level: Math.floor(xp / 100) + 1, graceDayAvailable, lastActivityDate: events[0] ? dayKey(events[0].occurredAt, offsetMinutes) : null, eventCount: events.length, historyTruncated: events.length >= 500 });
    } catch (error) {
        console.error('Error fetching learning stats:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

router.post('/note-read', authenticateUser, async (req, res) => {
    try {
        const { videoId } = req.body || {};
        if (!videoId || !mongoose.Types.ObjectId.isValid(videoId)) return res.status(400).json({ message: 'Invalid videoId' });
        const video = await Video.findById(videoId).select('_id');
        if (!video) return res.status(404).json({ message: 'Video not found' });
        await recordLearningEvent({ userId: req.user.id, type: 'note_read', sourceType: 'video', sourceId: videoId });
        res.status(201).json({ message: 'Note read recorded' });
    } catch (error) {
        console.error('Error recording note read:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
