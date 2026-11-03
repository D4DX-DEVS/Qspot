const mongoose = require('mongoose');

const subjectSchema = new mongoose.Schema({
    order: {
        type: Number,
        required: true
    },
    name: {
        type: String,
        required: true
    },
    image: {
        type: String,
        required: true
    },
    imageKey: {
        type: String
    },
    // The course this subject belongs to. Nullable: older subjects predate the
    // course hierarchy and simply have none.
    courseId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'course',
        default: null
    },
    isPublished: {
        type: Boolean,
        default: true
    },
    // Shown once, the first time a student opens this chapter: a short heading
    // plus what is inside it. Authored from the admin panel.
    guideTitle: {
        type: String,
        default: ''
    },
    guidePoints: {
        type: [{
            _id: false,
            icon: { type: String, default: 'info' },
            text: { type: String, default: '' }
        }],
        default: []
    }
}, {
    timestamps: true
});

subjectSchema.index({ courseId: 1 });

module.exports = mongoose.model('subject', subjectSchema);
