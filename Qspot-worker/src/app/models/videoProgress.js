const mongoose = require('mongoose');

// Per-user, per-video watch state. Stored on the server (not on the device) so
// progress follows the account, and so "completed" cannot be claimed without
// the watched seconds to back it up.
const videoProgressSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'user',
        required: true
    },
    videoId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'video',
        required: true
    },
    // Where to resume from.
    positionSeconds: {
        type: Number,
        default: 0
    },
    // Furthest point reached, used to show a resume hint.
    maxPositionSeconds: {
        type: Number,
        default: 0
    },
    // Sum of *forward playback* deltas. Seeking does not count, so this
    // reflects time actually watched rather than ground covered.
    watchedSeconds: {
        type: Number,
        default: 0
    },
    durationSeconds: {
        type: Number,
        default: 0
    },
    completed: {
        type: Boolean,
        default: false
    },
    completedAt: {
        type: Date,
        default: null
    },
    lastViewedAt: {
        type: Date,
        default: null
    }
}, {
    timestamps: true
});

videoProgressSchema.index({ userId: 1, videoId: 1 }, { unique: true });
videoProgressSchema.index({ videoId: 1 });

module.exports = mongoose.model('videoProgress', videoProgressSchema);
