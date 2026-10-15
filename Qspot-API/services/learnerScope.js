const User = require('../models/user');
const Subject = require('../models/subject');

// Which chapters (subjects) a learner can see: published chapters in the
// courses the learner picked. A learner who has picked no course sees nothing
// until they choose, so an empty list matches no chapter.
const subjectScopeFilter = (courseIds) => ({
    isPublished: { $ne: false },
    courseId: { $in: Array.isArray(courseIds) ? courseIds : [] }
});

const learnerSubjects = async (userId) => {
    const user = userId ? await User.findById(userId).select('courseIds').lean() : null;
    return Subject.find(subjectScopeFilter(user && user.courseIds))
        .select('_id name courseId order')
        .sort({ order: 1, createdAt: -1 })
        .lean();
};

// Signed-in learners are narrowed to their own courses; admins, faculty and
// anyone not signed in keep seeing everything.
const isScopedLearner = (user) => Boolean(user && user.userId && user.role === 'student');

module.exports = { subjectScopeFilter, learnerSubjects, isScopedLearner };
