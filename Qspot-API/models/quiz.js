const mongoose = require("mongoose");

const quizAttemptSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "user",
        required: true
    },
    language: {
        type: String,
        enum: ["Malayalam", "English"],
        default: "English",
    },
    questions: [{
        totalNumberOfQuestions: {
            type: Number,
            required: true
        },
        questionNumber: {
            type: String,
            required: true
        },
        question: {
            type: String,
            required: true
        },
        options: [{
            type: String,
            required: true
        }],
        correctAnswer: {
            type: String,
            required: true
        }
    }],
    answers: [{
        attemptedAnswer: {
            type: String,
            default: null
        },
        isCorrect: {
            type: String,
            required: true
        },
        duration: {
            type: Number,
            default: 0,
        },
    }],
    totalDuration: {
        type: Number,
        default: 0,
    },
    score: {
        type: Number,
        default: 0
    },
    percentage: {
        type: Number,
        default: 0,
    }
}, {
    timestamps: true
});

quizAttemptSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model("quiz", quizAttemptSchema);