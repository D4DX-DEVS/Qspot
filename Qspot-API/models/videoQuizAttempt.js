const mongoose = require('mongoose');

// A student's answers to the questions attached to one video.
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
    }
}, {
    timestamps: true
});

videoQuizAttemptSchema.index({ userId: 1, videoId: 1 }, { unique: true });
videoQuizAttemptSchema.index({ videoId: 1 });

module.exports = mongoose.model('videoQuizAttempt', videoQuizAttemptSchema);
