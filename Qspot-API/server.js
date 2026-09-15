// Suppress AWS SDK v2 deprecation warnings
process.removeAllListeners('warning');
process.on('warning', () => {});

const dns = require('dns');
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const app = express();

require('dotenv').config();

// Windows resolver fails MongoDB SRV lookups; force a resolver that supports them.
dns.setServers(['8.8.8.8', '1.1.1.1']);

app.use(cors());
app.use(express.json());

// Import routes
const adminRoutes = require('./routes/admin');
const bannerRoutes = require('./routes/banner');
const speakerRoutes = require('./routes/speakers');
const videoRoutes = require('./routes/videos');
const notificationRoutes = require('./routes/notifications');
const questionRoutes = require('./routes/questions');
const quizRoutes = require('./routes/quizzes');
const quizQuestionRoutes = require('./routes/quizQuestions');
const quizDefinitionRoutes = require('./routes/quizDefinitions');
const userQuizRoutes = require('./routes/userQuizzes');
const scheduleRoutes = require('./routes/schedules');
const subjectRoutes = require('./routes/subjects');
const userRoutes = require('./routes/users');

// Routes
app.use('/api/admin', adminRoutes);
app.use('/api/banner', bannerRoutes);
app.use('/api/speakers', speakerRoutes);
app.use('/api/videos', videoRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/questions', questionRoutes);
app.use('/api/quizzes', quizRoutes);
app.use('/api/quiz-questions', quizQuestionRoutes);
app.use('/api/quiz-definitions', quizDefinitionRoutes);
app.use('/api/user-quizzes', userQuizRoutes);
app.use('/api/schedules', scheduleRoutes);
app.use('/api/subjects', subjectRoutes);
app.use('/api/user', userRoutes);

const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI, {
            serverSelectionTimeoutMS: 10000,
            socketTimeoutMS: 45000,
        });
        console.log("Connected to MongoDB");
    } catch (error) {
        console.error("MongoDB connection error:", error.message);
        console.log("Retrying connection in 5 seconds...");
        setTimeout(connectDB, 5000);
    }
};

connectDB();


PORT = process.env.PORT;
app.listen(PORT, () => {
    console.log(`Server is running on port http://localhost:${PORT}`);
});
