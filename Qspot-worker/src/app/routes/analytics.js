const express = require('express');
const mongoose = require('mongoose');
const User = require('../models/user');
const VideoProgress = require('../models/videoProgress');
const VideoQuizAttempt = require('../models/videoQuizAttempt');
const VideoQuestion = require('../models/videoQuestions');
const Assignment = require('../models/assignment');
const AssignmentSubmission = require('../models/assignmentSubmission');
const Video = require('../models/videos');
const { authenticateAdmin } = require('../middlewares/auth');

const router = express.Router();

router.get('/overview', authenticateAdmin, async (req, res) => {
    try {
        const classFilter = String(req.query.class || '').trim();
        const videoId = req.query.videoId && mongoose.Types.ObjectId.isValid(req.query.videoId) ? req.query.videoId : null;
        const userFilter = { role: 'student' };
        if (classFilter) userFilter.class = classFilter;
        const [users, videos, questionCounts, assignments] = await Promise.all([
            User.find(userFilter).select('_id name class email learningEvents').sort({ name: 1 }).lean(),
            videoId ? Video.find({ _id: videoId }).select('_id title').lean() : Video.find({ isPublished: { $ne: false } }).select('_id title').lean(),
            VideoQuestion.aggregate([{ $match: videoId ? { videoId: new mongoose.Types.ObjectId(videoId) } : {} }, { $group: { _id: '$videoId', count: { $sum: 1 } } }]),
            Assignment.find({ isPublished: true }).select('_id dueAt class').lean()
        ]);
        const userIds = users.map((user) => user._id);
        const videoIds = videos.map((video) => video._id);
        const [progress, attempts, submissions] = await Promise.all([
            VideoProgress.find({ userId: { $in: userIds }, ...(videoId ? { videoId } : {}) }).select('userId videoId watchedSeconds completed durationSeconds').lean(),
            VideoQuizAttempt.find({ userId: { $in: userIds }, ...(videoId ? { videoId } : {}) }).select('userId videoId').lean(),
            AssignmentSubmission.find({ userId: { $in: userIds } }).select('userId assignmentId status submittedAt').lean()
        ]);
        const questionsByVideo = new Map(questionCounts.map((row) => [String(row._id), row.count]));
        const progressByUser = new Map();
        for (const row of progress) {
            const key = String(row.userId);
            const list = progressByUser.get(key) || [];
            list.push(row);
            progressByUser.set(key, list);
        }
        const attemptKeys = new Set(attempts.map((row) => `${row.userId}:${row.videoId}`));
        const noteKeys = new Set(users.flatMap((user) => (user.learningEvents || []).filter((event) => event.type === 'note_read').map((event) => `${user._id}:${event.sourceId}`)));
        const submittedByUser = new Map();
        submissions.forEach((submission) => {
            const key = String(submission.userId);
            submittedByUser.set(key, (submittedByUser.get(key) || 0) + 1);
        });
        const submissionKeys = new Set(submissions.map((submission) => `${submission.userId}:${submission.assignmentId}`));
        const learnerRows = users.map((user) => {
            const rows = progressByUser.get(String(user._id)) || [];
            const completed = rows.filter((row) => row.completed).length;
            const started = rows.filter((row) => (row.watchedSeconds || 0) > 0).length;
            const practiceReady = rows.filter((row) => row.completed && questionsByVideo.get(String(row.videoId)) && !attemptKeys.has(`${user._id}:${row.videoId}`)).length;
            const notesRead = videoIds.filter((id) => noteKeys.has(`${user._id}:${id}`)).length;
            const overdueAssignments = assignments.filter((assignment) => assignment.dueAt && new Date(assignment.dueAt) < new Date() && (!assignment.class || assignment.class === user.class) && !submissionKeys.has(`${user._id}:${assignment._id}`)).length;
            return { id: user._id, name: user.name, class: user.class, started, completed, notesRead, practiceReady, submittedAssignments: submittedByUser.get(String(user._id)) || 0, overdueAssignments };
        });
        const totals = learnerRows.reduce((acc, row) => {
            acc.started += row.started; acc.completed += row.completed; acc.notesRead += row.notesRead; acc.practiceReady += row.practiceReady; acc.submittedAssignments += row.submittedAssignments; acc.overdueAssignments += row.overdueAssignments;
            return acc;
        }, { started: 0, completed: 0, notesRead: 0, practiceReady: 0, submittedAssignments: 0, overdueAssignments: 0 });
        res.json({ filters: { class: classFilter || null, videoId }, videos, assignments: assignments.length, totals: { learners: users.length, ...totals }, learners: learnerRows });
    } catch (error) {
        console.error('Error fetching learning analytics:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
