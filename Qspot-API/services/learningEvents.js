const User = require('../models/user');

const XP = {
    video_started: 2,
    video_completed: 20,
    video_question_completed: 10,
    quiz_completed: 25,
    assignment_submitted: 15,
    note_read: 5
};

// XP of one stored event, as a database expression over $$event.
const eventXp = {
    $switch: {
        branches: Object.entries(XP).map(([type, points]) => ({ case: { $eq: ['$$event.type', type] }, then: points })),
        default: 0
    }
};

// An account from before running totals starts from what its saved events add
// up to. Runs once per account; afterwards the filter matches nothing.
const ensureXpTotal = (userId) => User.updateOne(
    { _id: userId, xpTotal: { $exists: false } },
    [{ $set: { xpTotal: { $reduce: {
        input: { $ifNull: ['$learningEvents', []] },
        initialValue: 0,
        in: { $add: ['$$value', { $let: { vars: { event: '$$this' }, in: eventXp } }] }
    } } } }]
);

const dayKey = (value = new Date(), offsetMinutes = 0) => {
    const date = new Date(value);
    return new Date(date.getTime() + offsetMinutes * 60 * 1000).toISOString().slice(0, 10);
};

const recordLearningEvent = async ({ userId, type, sourceType = '', sourceId = null, occurredAt = new Date(), offsetMinutes = 0, metadata = {} }) => {
    if (!userId || !type) return null;
    try {
        const key = dayKey(occurredAt, offsetMinutes);
        const event = { type, sourceType, sourceId, dayKey: key, occurredAt, metadata };
        await ensureXpTotal(userId);
        // The XP goes onto the running total in the same write as the event, so
        // a repeated event (refused by the filter) adds nothing.
        return await User.findOneAndUpdate(
            { _id: userId, learningEvents: { $not: { $elemMatch: { type, sourceType, sourceId, dayKey: key } } } },
            { $push: { learningEvents: { $each: [event], $slice: -500 } }, $inc: { xpTotal: XP[type] || 0 } },
            { new: true, projection: { learningEvents: { $slice: -1 } } }
        );
    } catch (error) {
        throw error;
    }
};

module.exports = { XP, dayKey, ensureXpTotal, recordLearningEvent };
