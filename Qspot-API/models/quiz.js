const mongoose = require("mongoose");

// A student's graded attempt at one quiz. Grading happens entirely on the
// server (see routes/quizzes.js): the client only ever sends the questionId +
// attemptedAnswer pairs, never a score.
const quizAttemptSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "user",
        required: true
    },
    quizId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "quizConfig",
        required: true
    },
    language: {
        type: String,
        enum: ["Malayalam", "English"],
        default: "English",
    },
    // The exact question ids served to this user for this attempt (from the
    // quizSession), so the attempt can always be re-graded / audited.
    questionIds: {
        type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'QuizQuestion' }],
        default: []
    },
    answers: [{
        _id: false,
        questionId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'QuizQuestion',
            required: true
        },
        attemptedAnswer: {
            type: mongoose.Schema.Types.Mixed,
            default: null
        },
        isCorrect: {
            type: Boolean,
            default: false
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
    totalQuestions: {
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

quizAttemptSchema.index({ userId: 1, quizId: 1 }, { unique: true });
quizAttemptSchema.index({ quizId: 1, score: -1, totalDuration: 1 });

module.exports = mongoose.model("quiz", quizAttemptSchema);
