// Lesson practice can be taken any number of times while it is open. One row
// per learner and lesson holds the best try; see models/videoQuizAttempt.js.

// Whether a video's practice accepts answers at [now].
const practiceOpen = (video, now = new Date()) => {
    if (!video || video.practiceEnabled === false) return false;
    if (video.practiceStartDate && now < new Date(video.practiceStartDate)) return false;
    if (video.practiceEndDate && now > new Date(video.practiceEndDate)) return false;
    return true;
};

// The fields to $set on an existing row for a new graded try. The best try is
// replaced only by a strictly higher percentage, so the earlier one wins a tie.
// try = { answers, score, totalQuestions, percentage, language }
const retakeUpdate = (existing, attempt, now = new Date()) => {
    const improved = attempt.percentage > (Number(existing.percentage) || 0);
    return {
        improved,
        set: {
            attemptCount: (Number(existing.attemptCount) || 1) + 1,
            lastScore: attempt.score,
            lastPercentage: attempt.percentage,
            lastAttemptAt: now,
            ...(improved
                ? {
                      answers: attempt.answers,
                      score: attempt.score,
                      totalQuestions: attempt.totalQuestions,
                      percentage: attempt.percentage,
                      language: attempt.language
                  }
                : {})
        }
    };
};

module.exports = { practiceOpen, retakeUpdate };
