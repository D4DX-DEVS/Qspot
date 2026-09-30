const mongoose = require('mongoose');

const assignmentSchema = new mongoose.Schema({
    title: { type: String, required: true, trim: true, maxlength: 200 },
    instructions: { type: String, default: '', maxlength: 10000 },
    courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'course', default: null },
    subjectId: { type: mongoose.Schema.Types.ObjectId, ref: 'subject', default: null },
    videoId: { type: mongoose.Schema.Types.ObjectId, ref: 'video', default: null },
    // Empty class means the assignment is available to every learner.
    class: { type: String, default: '', trim: true, maxlength: 80 },
    releaseAt: { type: Date, default: null },
    dueAt: { type: Date, default: null },
    maxPoints: { type: Number, default: 100, min: 1, max: 1000 },
    allowedMimeTypes: { type: [String], default: [] },
    maxFileSizeBytes: { type: Number, default: 10 * 1024 * 1024, min: 1, max: 100 * 1024 * 1024 },
    isPublished: { type: Boolean, default: false },
    createdBy: { type: String, default: '' },
    facultyProfile: { type: mongoose.Schema.Types.ObjectId, ref: 'speaker', default: null }
}, { timestamps: true });

assignmentSchema.index({ isPublished: 1, releaseAt: 1, dueAt: 1 });
assignmentSchema.index({ class: 1, isPublished: 1, dueAt: 1 });
assignmentSchema.index({ subjectId: 1, videoId: 1 });

module.exports = mongoose.model('assignment', assignmentSchema);
