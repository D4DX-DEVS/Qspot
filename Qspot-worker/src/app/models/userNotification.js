const mongoose = require('mongoose');

// One item in a learner's notification inbox: an announcement or something
// that happened to them (work marked, a quiz closing, a new lesson).
const userNotificationSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'user', required: true },
    kind: {
        type: String,
        enum: ['announcement', 'assignment_marked', 'assignment_returned', 'assignment_due', 'quiz_open', 'quiz_closing', 'lesson_released'],
        required: true
    },
    title: { type: String, required: true, maxlength: 200 },
    body: { type: String, default: '', maxlength: 2000 },
    target: {
        kind: { type: String, enum: ['none', 'lesson', 'quiz', 'assignment', 'course'], default: 'none' },
        id: { type: String, default: '' }
    },
    // Identifies the event, so the same event never reaches a learner twice
    // (e.g. "quiz_closing:<quizId>").
    sourceKey: { type: String, required: true },
    readAt: { type: Date, default: null },
    pushedAt: { type: Date, default: null }
}, { timestamps: true });

userNotificationSchema.index({ userId: 1, sourceKey: 1 }, { unique: true });
userNotificationSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('userNotification', userNotificationSchema);
