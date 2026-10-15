// Whether a quiz still accepts a submission.
//
// A student can finish a quiz with no signal and only reach the server after the
// quiz has closed. Their questions were fetched while it was live (that is what
// creates the quiz session), so for a short grace period after endDate a
// submission is still accepted. 'grace' tells the caller to additionally
// require that session, so nobody can start a quiz after it ended. 'ended'
// means the answers arrived after the grace period: too late to be marked.
const DEFAULT_GRACE_MINUTES = 5;

const submitGraceMs = (env = process.env) => {
    const minutes = Number(env.QUIZ_SUBMIT_GRACE_MINUTES ?? DEFAULT_GRACE_MINUTES);
    return Number.isFinite(minutes) && minutes > 0 ? minutes * 60 * 1000 : 0;
};

// -> 'open' (live now) | 'grace' (ended, still inside the grace period)
//  | 'ended' (past the grace period) | 'closed' (switched off or not started)
const submissionWindow = (config, now = new Date(), graceMs = submitGraceMs()) => {
    if (!config.isEnable || now < new Date(config.startDate)) return 'closed';
    const end = new Date(config.endDate);
    if (now <= end) return 'open';
    return now.getTime() - end.getTime() <= graceMs ? 'grace' : 'ended';
};

module.exports = { DEFAULT_GRACE_MINUTES, submitGraceMs, submissionWindow };
