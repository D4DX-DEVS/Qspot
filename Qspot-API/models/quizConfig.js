const mongoose = require("mongoose");

const quizConfigSchema = new mongoose.Schema({
    title: {
        type: String,
        trim: true,
        required: true
    },
    assessmentType: {
        type: String,
        enum: ['quiz', 'practical'],
        default: 'quiz'
    },
    startDate: {
        type: Date,
        required: true
    },
    endDate: {
        type: Date,
        required: true
    },
    numberOfQuestions: {
        type: Number,
        required: true
    },
    questionsRandomization: {
        type: Boolean,
        default: false,
        required: true
    },
    isEnable: {
        type: Boolean,
        default: false,
        required: true
    },
    overallTimeLimit: {
        type: Number,
        default: null
    },
    perQuestionTimeLimit: {
        type: Number,
        default: null
    },
    timerMode: {
        type: String,
        enum: ['none', 'overall', 'per-question', 'both'],
        default: 'none'
    },
    allowedClasses: {
        type: [String],
        default: []
    },
    conditions: {
        type: mongoose.Schema.Types.Mixed,
        default: {}
    },
    optionsCount: {
        type: Number,
        default: null
    }
}, {
    timestamps: true
});

quizConfigSchema.pre("save", async function (next) {
    if (!this.startDate || !this.endDate) {
        return next(new Error("startDate and endDate are required."));
    }
    if (this.startDate >= this.endDate) {
        return next(new Error("startDate must be before endDate."));
    }

    next();
});

quizConfigSchema.pre(["findOneAndUpdate", "updateOne", "update"], function (next) {
    const update = this.getUpdate() || {};
    const $set = update.$set || {};

    const start = $set.startDate;
    const end = $set.endDate;
    if (start && end && start >= end) {
        return next(new Error("startDate must be before endDate."));
    }

    next();
});

quizConfigSchema.virtual('isLive').get(function () {
    const now = new Date();
    return this.isEnable && this.startDate && this.endDate && now >= this.startDate && now <= this.endDate;
});

module.exports = mongoose.model("quizConfig", quizConfigSchema);
