const mongoose = require('mongoose');

const questionSchema = new mongoose.Schema({
    description: {
        type: String,
        required: true
    },
    faculty: {
        type: mongoose.Schema.Types.ObjectId,
        ref : "speaker",
        required : true
    },
    subject: {
        type: String,
        required: true
    },
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "user",
        required: true
    },
    answer: {
        type: String,
        default: null
    },
    answeredBy: {
        type: String,
        default: null
    },
    answeredAt: {
        type: Date,
        default: null
    }
}, {
    timestamps: true
});

// Virtual field to check if question is answered
questionSchema.virtual('isAnswered').get(function() {
    return this.answer !== null && this.answer !== undefined;
});

module.exports = mongoose.model('question', questionSchema);