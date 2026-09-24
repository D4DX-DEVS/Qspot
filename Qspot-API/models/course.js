const mongoose = require('mongoose');

// A course the app is running. The Home screen shows a card per active course
// and opens this content in an "About this course" popup.
const courseSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true
    },
    subtitle: {
        type: String,
        default: ''
    },
    description: {
        type: String,
        default: ''
    },
    learnPoints: {
        type: [String],
        default: []
    },
    image: {
        type: String,
        default: ''
    },
    // CDN key for an uploaded cover, so replacing or deleting a course can
    // clean up the file it leaves behind in Spaces.
    imageKey: {
        type: String,
        default: null
    },
    order: {
        type: Number,
        default: 0
    },
    isActive: {
        type: Boolean,
        default: true
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('course', courseSchema);
