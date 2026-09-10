const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    phone: {
        type: String,
        required: true
    },
    email: {
        type: String
    },
    class: {
        type : String,
        required : true
     }
}, {
    timestamps: true
});

module.exports = mongoose.model('user', userSchema);