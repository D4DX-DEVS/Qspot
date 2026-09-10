const mongoose = require('mongoose');

const speakerSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    designation: {
        type: String
    },
    image: {
        type: String,
        required: true
    },
    imageKey: {
        type: String
    },
    order: {
        type: String
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('speaker', speakerSchema);