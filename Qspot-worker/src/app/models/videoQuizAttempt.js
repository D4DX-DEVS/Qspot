const mongoose = require('mongoose');

// A student's best answers to the questions attached to one video.
const videoQuizAttemptSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'user',
        required: true
    },
    videoId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'video',
        required: true
    },
    language: {
        type: String,
        enum: ['Malayalam', 'English'],
        default: 'English'
    },
    answers: [{
        questionId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'videoQuestion',
            required: true
        },
        attemptedAnswer: {
            type: String,
            default: null
        },
        isCorrect: {
            type: Boolean,
            default: false
        }
    }],
    score: {
        type: Number,
        default: 0
    },
    totalQuestions: {
        type: Number,
        default: 0
    },
    percentage: {
        type: Number,
        default: 0
    },
    // Practice can be retaken. The fields above hold the best try (highest
    // percentage, earliest wins a tie); these record how many tries and the
    // most recent one. Rows saved before retakes existed have none of these
    // and count as one try.
    attemptCount: {
        type: Number,
        default: 1
    },
    lastScore: {
        type: Number,
        default: null
    },
    lastPercentage: {
        type: Number,
        default: null
    },
    lastAttemptAt: {
        type: Date,
        default: null
    }
}, {
    timestamps: true
});

videoQuizAttemptSchema.index({ userId: 1, videoId: 1 }, { unique: true });
videoQuizAttemptSchema.index({ videoId: 1 });

module.exports = mongoose.model('videoQuizAttempt', videoQuizAttemptSchema);
