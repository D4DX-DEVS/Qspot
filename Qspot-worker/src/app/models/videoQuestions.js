const mongoose = require('mongoose');

// Questions attached to one video. Same option/answer conventions as the quiz
// question model: options_en / options_ml are JSON-encoded arrays and
// correct_answer is the exact English option text.
const videoQuestionsSchema = new mongoose.Schema({
    videoId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'video',
        required: true
    },
    type: {
        type: String,
        required: true,
        trim: true,
        default: 'Multiple Choice'
    },
    question_en: {
        type: String,
        required: true,
        trim: true
    },
    question_ml: {
        type: String,
        required: true,
        trim: true
    },
    options_en: {
        type: String,
        required: true,
        trim: true
    },
    options_ml: {
        type: String,
        required: true,
        trim: true
    },
    correct_answer: {
        type: String,
        required: true,
        trim: true
    },
    difficulty: {
        type: String,
        required: true,
        trim: true,
        default: 'Easy'
    },
    order: {
        type: Number,
        default: 0
    }
}, {
    timestamps: true
});

videoQuestionsSchema.index({ videoId: 1, order: 1 });

module.exports = mongoose.model('videoQuestion', videoQuestionsSchema);
