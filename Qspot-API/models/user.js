const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    phone: {
        type: String,
        required: true,
        unique: true
    },
    email: {
        type: String,
        default: ''
    },
    profileImage: {
        type: String,
        default: ''
    },
    profileImageKey: {
        type: String,
        default: ''
    },
    class: {
        type: String,
        required: true
    },
    courseIds: {
        type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'course' }],
        default: []
    },
    role: {
        type: String,
        enum: ['student', 'faculty', 'admin'],
        default: 'student'
    },
    facultyProfile: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'speaker',
        default: null
    },
    dob: {
        type: Date,
        default: null
    },
    // Whether the phone number has been confirmed with a one-time code. Defaults
    // to true so accounts created before this field existed (every one of them
    // signed in with a code) read as verified; /register sets it to false.
    phoneVerified: {
        type: Boolean,
        default: true
    },
    consent: {
        by: { type: String, enum: ['parent', 'school'], default: undefined },
        name: { type: String, default: '' },
        at: { type: Date, default: null }
    },
    language: {
        type: String,
        enum: ['en', 'ml'],
        default: 'en'
    },
    bookmarks: {
        type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'video' }],
        default: []
    },
    // Phones that can receive push notifications (filled once a push service
    // is connected; see services/pushSender.js).
    pushTokens: {
        type: [{
            _id: false,
            token: { type: String, required: true, maxlength: 4096 },
            platform: { type: String, enum: ['android', 'ios', 'web', 'other'], default: 'other' },
            updatedAt: { type: Date, default: Date.now }
        }],
        default: [],
        select: false
    },
    seenGuides: {
        type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'subject' }],
        default: []
    },
    learningEvents: {
        type: [{
            _id: false,
            type: { type: String, enum: ['video_started', 'video_completed', 'video_question_completed', 'quiz_completed', 'assignment_submitted', 'note_read'] },
            sourceType: { type: String, default: '' },
            sourceId: { type: mongoose.Schema.Types.ObjectId, default: null },
            dayKey: { type: String },
            occurredAt: { type: Date, default: Date.now },
            metadata: { type: mongoose.Schema.Types.Mixed, default: {} }
        }],
        default: []
    },
    // Running totals beside learningEvents, which keeps only the latest 500:
    // trimming old events never lowers a learner's XP or best streak.
    // xpTotal is missing on older accounts until it is filled from their events.
    xpTotal: { type: Number },
    bestStreak: { type: Number, default: 0 }
}, {
    timestamps: true
});

module.exports = mongoose.model('user', userSchema);
