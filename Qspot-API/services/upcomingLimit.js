// How many upcoming items /api/user/today sends back. Today shows a short
// list, so the default stays at 12; the Calendar asks for more.
const DEFAULT_UPCOMING_LIMIT = 12;
const MAX_UPCOMING_LIMIT = 200;

const parseUpcomingLimit = (value) => {
    const parsed = Number.parseInt(value, 10);
    if (!Number.isInteger(parsed) || parsed < 1) return DEFAULT_UPCOMING_LIMIT;
    return Math.min(parsed, MAX_UPCOMING_LIMIT);
};

module.exports = { parseUpcomingLimit, DEFAULT_UPCOMING_LIMIT, MAX_UPCOMING_LIMIT };
