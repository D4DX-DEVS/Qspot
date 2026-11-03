// Lesson counts for the learner's Progress screen. Totals are every lesson the
// learner can open now (published, in their courses, already released), not only
// the ones they have started, so 1 finished out of 40 reads 2.5%, not 100%.

const isUpcoming = (releaseDate, now) => {
    if (!releaseDate) return false;
    const parsed = new Date(releaseDate);
    if (Number.isNaN(parsed.getTime())) return false;
    return parsed.getTime() > now.getTime();
};

const hasStarted = (row) =>
    (Number(row.watchedSeconds) || 0) > 0 || (Number(row.positionSeconds) || 0) > 0;

// subjects, videos: the learner's scope (see services/learnerScope.js).
// progressRows: this learner's rows. courseTitles: Map of course id string to title.
const buildProgressSummary = ({ subjects, videos, progressRows, courseTitles = new Map(), now = new Date() }) => {
    const subjectById = new Map(subjects.map((subject) => [String(subject._id), subject]));
    const progressByVideo = new Map(progressRows.map((row) => [String(row.videoId), row]));

    const totals = { total: 0, completed: 0, inProgress: 0 };
    const perSubject = new Map();

    for (const video of videos) {
        const subject = subjectById.get(String(video.subject));
        if (!subject || isUpcoming(video.releaseDate, now)) continue;

        const row = progressByVideo.get(String(video._id));
        const entry = perSubject.get(String(subject._id)) || { total: 0, completed: 0 };
        entry.total += 1;
        totals.total += 1;
        if (row && row.completed) {
            entry.completed += 1;
            totals.completed += 1;
        } else if (row && hasStarted(row)) {
            totals.inProgress += 1;
        }
        perSubject.set(String(subject._id), entry);
    }

    const subjectRows = [];
    const perCourse = new Map();
    for (const subject of subjects) {
        const entry = perSubject.get(String(subject._id));
        if (!entry) continue;
        subjectRows.push({ subjectId: subject._id, name: subject.name, total: entry.total, completed: entry.completed });

        if (!subject.courseId) continue;
        const courseKey = String(subject.courseId);
        const course = perCourse.get(courseKey) || {
            courseId: subject.courseId,
            title: courseTitles.get(courseKey) || '',
            total: 0,
            completed: 0
        };
        course.total += entry.total;
        course.completed += entry.completed;
        perCourse.set(courseKey, course);
    }

    return { videos: totals, subjects: subjectRows, courses: [...perCourse.values()] };
};

module.exports = { buildProgressSummary, isUpcoming };
