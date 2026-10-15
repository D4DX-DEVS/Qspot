const mongoose = require('mongoose');

// An admin announcement. It reaches each learner in its audience as a
// personal inbox item (see models/userNotification.js) once its send time
// has come; services/notificationJobs.js does the sending.
const notificationSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true
    },
    description: {
        type: String,
        required: true
    },
    // Who receives it: everyone, one class, or the learners in one course.
    audience: {
        kind: { type: String, enum: ['all', 'class', 'course'], default: 'all' },
        value: { type: String, default: '' }
    },
    // The screen a tap opens. 'none' shows the text only.
    target: {
        kind: { type: String, enum: ['none', 'lesson', 'quiz', 'assignment', 'course'], default: 'none' },
        id: { type: String, default: '' }
    },
    // When to send. Announcements saved before scheduling existed have none
    // and count as sent when created.
    sendAt: { type: Date, default: null },
    dispatchedAt: { type: Date, default: null },
    recipientCount: { type: Number, default: 0 }
}, {
    timestamps: true
});

notificationSchema.index({ dispatchedAt: 1, sendAt: 1 });

module.exports = mongoose.model('notification', notificationSchema);
