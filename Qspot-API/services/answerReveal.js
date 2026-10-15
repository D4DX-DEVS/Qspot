// When learners may see the correct answers to an exam or a practice set.
//
// Correct answers stay hidden until nobody can still submit, so they cannot be
// passed around while classmates are answering. For an exam that is the end of
// its submission window (end date plus the grace period). For lesson practice
// it is the practice end date; practice with no end date never shows them,
// because it can be retaken as often as a learner likes.
const { submitGraceMs } = require('./quizWindow');

const validDate = (value) => {
    if (!value) return null;
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
};

// -> Date the exam's answers become visible, or null when it has no end date.
const examAnswersAt = (config, graceMs = submitGraceMs()) => {
    const end = validDate(config && config.endDate);
    return end ? new Date(end.getTime() + graceMs) : null;
};

// -> Date a lesson's practice answers become visible, or null (never).
const practiceAnswersAt = (video) => validDate(video && video.practiceEndDate);

const answersRevealed = (availableAt, now = new Date()) =>
    availableAt instanceof Date && now.getTime() >= availableAt.getTime();

// The fields every learner-facing attempt response carries. Per-question
// results (which include the correct answers) are only sent once revealed.
const revealFields = (availableAt, results, now = new Date()) => {
    const revealed = answersRevealed(availableAt, now);
    return {
        answersRevealed: revealed,
        answersAvailableAt: availableAt,
        results: revealed ? results : []
    };
};

module.exports = { examAnswersAt, practiceAnswersAt, answersRevealed, revealFields };
