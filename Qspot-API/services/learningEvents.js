const User = require('../models/user');

const dayKey = (value = new Date(), offsetMinutes = 0) => {
    const date = new Date(value);
    return new Date(date.getTime() + offsetMinutes * 60 * 1000).toISOString().slice(0, 10);
};

const recordLearningEvent = async ({ userId, type, sourceType = '', sourceId = null, occurredAt = new Date(), offsetMinutes = 0, metadata = {} }) => {
    if (!userId || !type) return null;
    try {
        const key = dayKey(occurredAt, offsetMinutes);
        const event = { type, sourceType, sourceId, dayKey: key, occurredAt, metadata };
        return await User.findOneAndUpdate(
            { _id: userId, learningEvents: { $not: { $elemMatch: { type, sourceType, sourceId, dayKey: key } } } },
            { $push: { learningEvents: { $each: [event], $slice: -500 } } },
            { new: true, projection: { learningEvents: { $slice: -1 } } }
        );
    } catch (error) {
        throw error;
    }
};

module.exports = { dayKey, recordLearningEvent };
