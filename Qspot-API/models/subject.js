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
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('subject', subjectSchema);