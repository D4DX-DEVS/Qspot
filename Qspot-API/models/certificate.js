const mongoose = require('mongoose');

const certificateSchema = new mongoose.Schema({
    certificateNumber: {
        type: String,
        required: true,
        unique: true,
        index: true
    },
    quizId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'quizConfig',
        required: true,
        index: true
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'user',
        required: true,
        index: true
    },
    percentage: {
        type: Number,
        required: true,
        min: 0,
        max: 100
    },
    score: {
        type: Number,
        required: true,
        min: 0
    },
    totalQuestions: {
        type: Number,
        required: true,
        min: 0
    },
    issuedAt: {
        type: Date,
        default: Date.now
    },
    status: {
        type: String,
        enum: ['issued', 'revoked'],
        default: 'issued',
        index: true
    },
    revokedAt: {
        type: Date,
        default: null
    },
    // Keep the certificate printable and auditable even if the exam settings
    // are edited after issuance.
    snapshot: {
        title: { type: String, default: 'Certificate of Achievement' },
        issuerName: { type: String, default: '' },
        signatoryName: { type: String, default: '' },
        description: { type: String, default: '' },
        examTitle: { type: String, default: '' }
    }
}, {
    timestamps: true
});

certificateSchema.index({ quizId: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model('certificate', certificateSchema);
