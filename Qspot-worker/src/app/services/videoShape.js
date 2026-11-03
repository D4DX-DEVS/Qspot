// What a lesson looks like in a reply. Used by every route that sends lessons
// to students, so they all hide the same things.

const isUpcoming = (releaseDate) => {
    if (!releaseDate) return false;
    const parsed = new Date(releaseDate);
    if (Number.isNaN(parsed.getTime())) return false;
    return parsed.getTime() > Date.now();
};

// Admin gets everything. Students never get the storage file name (stored
// files are public, so the name alone opens the file), and an unreleased
// lesson sends only what its "coming soon" card shows: no link, handouts or
// notes that could be opened before the release date.
const shapeVideo = (video, questionCount, isAdmin) => {
    const obj = video.toObject ? video.toObject() : { ...video };
    const upcoming = isUpcoming(obj.releaseDate);

    if (isAdmin) {
        return { ...obj, isUpcoming: upcoming, questionCount: questionCount || 0 };
    }
    if (upcoming) {
        const { _id, title, subject, speaker, releaseDate, order } = obj;
        return { _id, title, subject, speaker, releaseDate, order, video: '', isUpcoming: true, questionCount: 0 };
    }
    delete obj.videoKey;
    return { ...obj, isUpcoming: false, questionCount: questionCount || 0 };
};

module.exports = { isUpcoming, shapeVideo };
