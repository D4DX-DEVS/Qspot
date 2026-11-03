// Puts notifications in learners' inboxes and pushes them to their phones.
const User = require('../models/user');
const UserNotification = require('../models/userNotification');
const { sendPush, pickProvider, providers } = require('./pushSender');

// Accounts saved before roles existed have no role and are learners.
const learnerQuery = (extra = {}) => ({ $or: [{ role: 'student' }, { role: { $exists: false } }], ...extra });

// Learner ids for an audience: everyone, some classes, or one course.
const learnerIds = async ({ classes = null, courseId = null } = {}) => {
    const filter = learnerQuery();
    if (Array.isArray(classes) && classes.length) filter.class = { $in: classes };
    if (courseId) filter.courseIds = courseId;
    return User.find(filter).distinct('_id');
};

const pushToNew = async (created, item) => {
    if (!created.length || pickProvider() === providers.none) return;
    const users = await User.find({ _id: { $in: created.map((c) => c.userId) } }).select('+pushTokens').lean();
    const tokensByUser = new Map(users.map((u) => [String(u._id), (u.pushTokens || []).map((t) => t.token)]));
    await Promise.all(created.map(({ userId, notificationId }) => sendPush(tokensByUser.get(String(userId)) || [], {
        title: item.title,
        body: item.body || '',
        data: { kind: item.kind, targetKind: item.target?.kind || 'none', targetId: item.target?.id || '', notificationId: String(notificationId) }
    })));
};

// Adds one inbox item per learner for an event. A learner who already has
// this event (same sourceKey) is skipped, so jobs can run repeatedly and on
// several servers. Returns how many learners got it now.
// item = { kind, title, body, target: { kind, id }, sourceKey }
const deliver = async (userIds, item) => {
    const ids = [...new Set((userIds || []).map(String))];
    if (!ids.length) return 0;
    const ops = ids.map((userId) => ({
        updateOne: {
            filter: { userId, sourceKey: item.sourceKey },
            update: {
                $setOnInsert: {
                    userId,
                    kind: item.kind,
                    title: String(item.title).slice(0, 200),
                    body: String(item.body || '').slice(0, 2000),
                    target: item.target || { kind: 'none', id: '' },
                    sourceKey: item.sourceKey
                }
            },
            upsert: true
        }
    }));
    let upserted = {};
    try {
        const result = await UserNotification.bulkWrite(ops, { ordered: false });
        upserted = result.upsertedIds || {};
    } catch (error) {
        // Another server added the same item at the same moment: fine.
        if (error.code !== 11000 && !(error.writeErrors || []).every((e) => e.code === 11000)) throw error;
        upserted = error.result?.upsertedIds || error.result?.result?.upsertedIds || {};
    }
    const created = Object.entries(upserted).map(([index, notificationId]) => ({ userId: ids[Number(index)], notificationId }));
    await pushToNew(created, item);
    return created.length;
};

// A teacher marked the work, or sent it back for changes.
const notifyAssignmentReviewed = async (submission, assignment) => {
    const returned = submission.status === 'returned';
    if (!returned && submission.status !== 'graded') return 0;
    const at = submission.gradedAt ? new Date(submission.gradedAt).getTime() : Date.now();
    const userId = submission.userId?._id || submission.userId;
    const kind = returned ? 'assignment_returned' : 'assignment_marked';
    return deliver([userId], {
        kind,
        title: returned
            ? `Your teacher asked for changes: ${assignment.title}`
            : `Your teacher marked ${assignment.title}`,
        body: returned
            ? 'Read the feedback and send your work again.'
            : `Score: ${submission.grade}/${assignment.maxPoints}. Tap to read the feedback.`,
        target: { kind: 'assignment', id: String(assignment._id) },
        sourceKey: `${kind}:${submission._id}:${at}`
    });
};

module.exports = { deliver, learnerIds, learnerQuery, notifyAssignmentReviewed };
