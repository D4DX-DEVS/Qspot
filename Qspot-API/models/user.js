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
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('user', userSchema);
