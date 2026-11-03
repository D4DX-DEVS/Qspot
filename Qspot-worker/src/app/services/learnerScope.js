const User = require('../models/user');
const Subject = require('../models/subject');

// Temporarily off: every learner sees every published chapter, whatever
// courses they picked. Set back to true to narrow learners to their courses.
const SCOPE_TO_CHOSEN_COURSES = false;

// Which chapters (subjects) a learner can see: published chapters in the
// courses the learner picked. A learner who has picked no course sees nothing
// until they choose, so an empty list matches no chapter.
const subjectScopeFilter = (courseIds) => ({
    isPublished: { $ne: false },
    courseId: { $in: Array.isArray(courseIds) ? courseIds : [] }
});

const learnerSubjects = async (userId) => {
    let filter = { isPublished: { $ne: false } };
    if (SCOPE_TO_CHOSEN_COURSES) {
        const user = userId ? await User.findById(userId).select('courseIds').lean() : null;
        filter = subjectScopeFilter(user && user.courseIds);
    }
    return Subject.find(filter)
        .select('_id name courseId order')
        .sort({ order: 1, createdAt: -1 })
        .lean();
};

// Signed-in learners are narrowed to their own courses; admins, faculty and
// anyone not signed in keep seeing everything.
const isScopedLearner = (user) =>
    SCOPE_TO_CHOSEN_COURSES && Boolean(user && user.userId && user.role === 'student');

module.exports = { SCOPE_TO_CHOSEN_COURSES, subjectScopeFilter, learnerSubjects, isScopedLearner };
