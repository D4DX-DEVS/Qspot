const mongoose = require('mongoose');

const scheduleSchema = new mongoose.Schema({
    class: {
       type : String,
       required : true
    },
    scheduleDate: {
       type : Date,
       required : true
    },
    faculty: {
        type : mongoose.Schema.Types.ObjectId,
        ref : "speaker",
        required : true
    },
    title: {
        type : String,
        required : true
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('schedule', scheduleSchema);