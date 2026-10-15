// Checks the time a student's app reports for each question against the
// quiz's time limits.
//
// The quiz runs on the phone (it works offline), so the phone measures how long
// each question took to answer. Only those durations are compared with the
// limits: no phone timestamps are needed, so a phone clock that is wrong, or a
// slow connection while lining clocks up, can never make an answer look late.
// An answer reported as taking longer than allowed is thrown out (status
// 'timed_out'); the app itself never allows one, so this only catches a
// modified app or a hand-made request.
const TOLERANCE_SECONDS = 3; // 1 s timer ticks + rounding

const STATUS = Object.freeze({
    ANSWERED: 'answered',
    SKIPPED: 'skipped',
    TIMED_OUT: 'timed_out',
    NOT_REACHED: 'not_reached'
});

const toSeconds = (value) => {
    const n = Number(value);
    return Number.isFinite(n) && n >= 0 ? Math.round(n * 10) / 10 : 0;
};

const limitsOf = (config) => {
    const mode = config?.timerMode || 'none';
    const perQuestion = Number(config?.perQuestionTimeLimit) || 0;
    const overall = Number(config?.overallTimeLimit) || 0;
    return {
        perQuestion: (mode === 'per-question' || mode === 'both') && perQuestion > 0 ? perQuestion : 0,
        overall: (mode === 'overall' || mode === 'both') && overall > 0 ? overall : 0
    };
};

// entries: one per served question, in order: { attemptedIndex, submitted }
// where `submitted` is what the app sent for that question (or undefined).
// `submitted.duration` is the seconds it took to answer; for an unanswered
// question, the seconds it was on screen (the full limit when its time ran out).
const assessTiming = ({ config, startedAt, receivedAt, totalDuration, entries }) => {
    const { perQuestion, overall } = limitsOf(config);
    const hasTimingData = entries.some(({ submitted }) => submitted && submitted.duration !== undefined);

    let used = 0;
    const answers = entries.map(({ attemptedIndex, submitted = {} }) => {
        const answered = attemptedIndex !== null && attemptedIndex !== undefined;
        if (!hasTimingData) {
            // An older app sends no timing: keep the answer as it is.
            return { status: answered ? STATUS.ANSWERED : undefined, duration: 0, voided: false };
        }
        const duration = toSeconds(submitted.duration);
        used += duration;
        const voided = answered && (
            (perQuestion > 0 && duration > perQuestion + TOLERANCE_SECONDS)
            || (overall > 0 && used > overall + TOLERANCE_SECONDS)
        );
        const status = answered && !voided ? STATUS.ANSWERED
            : voided || (perQuestion > 0 && duration >= perQuestion) ? STATUS.TIMED_OUT
            : duration > 0 ? STATUS.SKIPPED
            : STATUS.NOT_REACHED;
        return { status, duration, voided };
    });

    // Time taken comes from the phone; it can never be more than the time the
    // server saw pass since the quiz was opened.
    const start = startedAt ? new Date(startedAt) : null;
    const received = receivedAt ? new Date(receivedAt) : new Date();
    const elapsed = start && !Number.isNaN(start.getTime())
        ? Math.max(0, Math.round((received - start) / 1000))
        : null;
    const reported = Math.max(0, Math.round(Number(totalDuration) || 0));
    return {
        answers,
        totalDuration: elapsed === null ? reported : Math.min(reported, elapsed),
        hasTimingData
    };
};

module.exports = { assessTiming, STATUS, TOLERANCE_SECONDS };
