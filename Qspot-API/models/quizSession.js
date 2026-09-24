const mongoose = require('mongoose');

// The set of questions served to one user for one quiz. Repeat calls to
// GET /api/user-quizzes/:id/questions return the SAME set (and order) by
// reading this back instead of re-selecting, so a page refresh mid-quiz does
// not hand the student a different set of questions than the one they started
// grading against.
const quizSessionSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'user',
        required: true
    },
    quizId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'quizConfig',
        required: true
    },
    questionIds: {
        type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'QuizQuestion' }],
        default: []
    },
    startedAt: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

quizSessionSchema.index({ userId: 1, quizId: 1 }, { unique: true });

module.exports = mongoose.model('quizSession', quizSessionSchema);
