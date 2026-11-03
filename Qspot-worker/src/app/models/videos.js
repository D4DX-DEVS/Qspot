const mongoose = require('mongoose');

const videoSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true
    },
    description: {
        type: String
    },
    video: {
        type: String,
        required: true
    },
    videoKey: {
        type: String
    },
    subject: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "subject",
        required: true
    },
    // The faculty member who presents this episode. Optional: older episodes
    // predate the link and simply have none.
    speaker: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'speaker',
        default: null
    },
    // Episode number within its subject. Public listings sort by this, not by
    // upload order.
    order: {
        type: Number,
        default: 0
    },
    isPublished: {
        type: Boolean,
        default: true
    },
    durationSeconds: {
        type: Number,
        default: 0
    },
    practiceEnabled: { type: Boolean, default: true },
    practiceTimerMode: {
        type: String,
        enum: ['none', 'overall', 'per-question', 'both'],
        default: 'none'
    },
    practiceOverallTimeLimit: { type: Number, default: null },
    practicePerQuestionTimeLimit: { type: Number, default: null },
    practiceStartDate: { type: Date, default: null },
    practiceEndDate: { type: Date, default: null },
    practiceConditions: { type: mongoose.Schema.Types.Mixed, default: {} },
    // Stored as a String (ISO date) for backward compatibility with existing
    // rows; routes accept ISO strings and compare as Date.
    releaseDate: {
        type: String
    },
    // "Learn" tab: a short note on what this episode covers, plus optional
    // takeaway lines. Authored from the admin panel.
    learnText: {
        type: String,
        default: ''
    },
    learnPoints: {
        type: [String],
        default: []
    },
    // "Downloads" tab: handouts for this episode. `key` is the CDN object key
    // (when the file was uploaded through the admin panel) so removing a
    // download or deleting the video can also delete the file it left behind.
    downloads: {
        type: [{
            _id: false,
            title: { type: String, default: '' },
            url: { type: String, default: '' },
            key: { type: String, default: null }
        }],
        default: []
    }
}, {
    timestamps: true
});

videoSchema.index({ subject: 1, order: 1 });
videoSchema.index({ speaker: 1 });

module.exports = mongoose.model('video', videoSchema);
