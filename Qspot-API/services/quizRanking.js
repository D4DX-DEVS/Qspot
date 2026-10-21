// Ranks the attempts at one quiz for the admin: more correct answers first,
// then less time taken. Students with the same score and the same time share
// a rank and the next one is skipped (1, 2, 2, 4).

// The order to read attempts in. Tied students stay in the order they
// submitted, so the list is the same on every load.
const RANK_SORT = { score: -1, totalDuration: 1, createdAt: 1, _id: 1 };

const scoreOf = (attempt) => Number(attempt.score) || 0;
const timeOf = (attempt) => Number(attempt.totalDuration) || 0;

// attempts: every attempt at the quiz, read in RANK_SORT order.
const withRanks = (attempts) => {
    let rank = 0;
    return attempts.map((attempt, index) => {
        const before = attempts[index - 1];
        if (!before || scoreOf(before) !== scoreOf(attempt) || timeOf(before) !== timeOf(attempt)) {
            rank = index + 1;
        }
        return { attempt, rank };
    });
};

module.exports = { RANK_SORT, withRanks };
