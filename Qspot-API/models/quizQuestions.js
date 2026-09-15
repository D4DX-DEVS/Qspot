const mongoose = require('mongoose');

const quizQuestionsSchema = new mongoose.Schema({
    quizId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "quizConfig",
        default: null
    },
    type: {
        type: String,
        required: true,
        trim: true,
    },
    question_en: {
        type: String,
        required: true,
        trim: true,
    },
    question_ml: {
        type: String,
        required: true,
        trim: true,
    },
    options_en: {
        type: String,
        required: true,
        trim: true,
    },
    options_ml: {
        type: String,
        required: true,
        trim: true,
    },
    correct_answer: {
        type: String,
        required: true,
        trim: true,
    },
    difficulty: {
        type: String,
        required: true,
        trim: true,
    },
},
    { timestamps: true }
);

module.exports = mongoose.model('QuizQuestion', quizQuestionsSchema);