const mongoose = require('mongoose');

const fileSchema = new mongoose.Schema({
    name: { type: String, required: true, trim: true, maxlength: 255 },
    url: { type: String, required: true, trim: true, maxlength: 2000 },
    key: { type: String, default: null, trim: true, maxlength: 500 },
    mimeType: { type: String, default: 'application/octet-stream', trim: true, maxlength: 120 },
    size: { type: Number, default: 0, min: 0 }
}, { _id: false });

const assignmentSubmissionSchema = new mongoose.Schema({
    assignmentId: { type: mongoose.Schema.Types.ObjectId, ref: 'assignment', required: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'user', required: true },
    text: { type: String, default: '', maxlength: 20000 },
    files: { type: [fileSchema], default: [] },
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
    status: { type: String, enum: ['submitted', 'late', 'graded', 'returned'], default: 'submitted' },
    grade: { type: Number, min: 0, default: null },
    feedback: { type: String, default: '', maxlength: 10000 },
    submittedAt: { type: Date, default: Date.now },
    gradedAt: { type: Date, default: null },
    gradedBy: { type: String, default: '' }
}, { timestamps: true });

assignmentSubmissionSchema.index({ assignmentId: 1, userId: 1 }, { unique: true });
assignmentSubmissionSchema.index({ userId: 1, submittedAt: -1 });
assignmentSubmissionSchema.index({ assignmentId: 1, status: 1, submittedAt: -1 });

module.exports = mongoose.model('assignmentSubmission', assignmentSubmissionSchema);
