const mongoose = require('mongoose');

const videoSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true
    },
    description: {
        type: String
    },
    video: {
        type: String,
        required: true
    },
    videoKey: {
        type: String
    },
    subject: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "subject",
        required: true
    },
    releaseDate: {
        type: String
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('video', videoSchema);