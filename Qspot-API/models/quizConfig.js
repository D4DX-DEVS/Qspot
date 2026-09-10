const mongoose = require("mongoose");

const quizConfigSchema = new mongoose.Schema({
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
    }
}, {
    timestamps: true
});

quizConfigSchema.pre("save", async function (next) {
    if (this.isNew) {
        const existingConfig = await mongoose.model("quizConfig").findOne();
        if (existingConfig) {
            return next(new Error("Only one quiz configuration is allowed in the system. Please update or delete the existing configuration first."));
        }
    }

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
    return this.startDate && this.endDate && now >= this.startDate && now <= this.endDate;
});

module.exports = mongoose.model("quizConfig", quizConfigSchema);

