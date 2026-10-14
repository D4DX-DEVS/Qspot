const VideoProgress = require('../models/videoProgress');

// "Has this student finished a video?", asked at most once per request no
// matter how many quizzes need the answer. `exists` is replaceable in tests.
const completedVideoCheck = (user, exists = (filter) => VideoProgress.exists(filter)) => {
    let answer = null;
    return () => {
        answer ??= Promise.resolve(exists({ userId: user.id, completed: true })).then(Boolean);
        return answer;
    };
};

// Whether the student may see [quiz]: their class is allowed and, when the
// quiz requires it, they have finished a video.
const isAccessible = async (quiz, user, hasCompletedVideo = completedVideoCheck(user)) => {
    const allowed = Array.isArray(quiz.allowedClasses) ? quiz.allowedClasses.filter(Boolean) : [];
    if (allowed.length > 0 && !allowed.includes(String(user.class || ''))) return false;
    if (quiz.conditions?.requireCompletedVideo && !(await hasCompletedVideo())) return false;
    return true;
};

module.exports = { isAccessible, completedVideoCheck };
