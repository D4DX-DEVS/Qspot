/**
 * Attach sample "watch the video, now answer" questions to two real videos so
 * the video-quiz flow can be demonstrated end to end.
 *
 *   node scripts/seed-video-questions.js
 *
 * The questions are answerable from the video itself (topic, speaker, episode
 * number), so they are honest placeholders — replace them in the admin panel
 * with real comprehension questions.
 */
require('dotenv').config();

const mongoose = require('mongoose');
const Video = require('../models/videos');
const VideoQuestion = require('../models/videoQuestions');

// Place the correct option at a different position each time so the quiz is not
// trivially "always pick the first one".
const withCorrectAt = (options, correct, index) => {
    const others = options.filter((o) => o !== correct);
    others.splice(index % options.length, 0, correct);
    return others;
};

const build = (videoId, rows) =>
    rows.map((row, i) => {
        const correctMl = row.options_ml[row.options_en.indexOf(row.correct)];
        return {
            videoId,
            type: 'Multiple Choice',
            question_en: row.question_en,
            question_ml: row.question_ml,
            options_en: JSON.stringify(withCorrectAt(row.options_en, row.correct, i)),
            options_ml: JSON.stringify(withCorrectAt(row.options_ml, correctMl, i)),
            correct_answer: row.correct,
            difficulty: row.difficulty || 'Easy',
            order: i
        };
    });

async function main() {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('connected:', mongoose.connection.name);

    const targets = [
        {
            match: /Episode 30/i,
            rows: [
                {
                    question_en: 'What is the topic of this episode?',
                    question_ml: 'ഈ എപ്പിസോഡിന്റെ വിഷയം എന്താണ്?',
                    options_en: ['Unblemished faith', 'Quran and other scriptures', 'Patience', 'Supplication'],
                    options_ml: ['കളങ്കമില്ലാത്ത ഈമാൻ', 'ഖുർആനും ഇതര വേദങ്ങളും', 'സബർ', 'ദുആ'],
                    correct: 'Unblemished faith'
                },
                {
                    question_en: 'Who presents this episode?',
                    question_ml: 'ഈ എപ്പിസോഡ് അവതരിപ്പിക്കുന്നത് ആരാണ്?',
                    options_en: ['Basheer Muhiyudheen', 'Suhaib CT', 'Salman Azhari', 'Afra Shihab'],
                    options_ml: ['ബശീർ മുഹ്യിദ്ദീൻ', 'സി ടി സുഹൈബ്', 'സൽമാൻ അസ്ഹരി', 'അഫ്റ ഷിഹാബ്'],
                    correct: 'Basheer Muhiyudheen',
                    difficulty: 'Medium'
                },
                {
                    question_en: 'Which episode number is this?',
                    question_ml: 'ഇത് എത്രാമത്തെ എപ്പിസോഡ് ആണ്?',
                    options_en: ['30', '29', '28', '31'],
                    options_ml: ['30', '29', '28', '31'],
                    correct: '30'
                }
            ]
        },
        {
            match: /Episode 29/i,
            rows: [
                {
                    question_en: 'What is the topic of this episode?',
                    question_ml: 'ഈ എപ്പിസോഡിന്റെ വിഷയം എന്താണ്?',
                    options_en: ['Quran and other scriptures', 'Unblemished faith', 'Charity', 'Prayer'],
                    options_ml: ['ഖുർആനും ഇതര വേദങ്ങളും', 'കളങ്കമില്ലാത്ത ഈമാൻ', 'ദാനധർമ്മം', 'നമസ്കാരം'],
                    correct: 'Quran and other scriptures'
                },
                {
                    question_en: 'Who presents this episode?',
                    question_ml: 'ഈ എപ്പിസോഡ് അവതരിപ്പിക്കുന്നത് ആരാണ്?',
                    options_en: ['Suhaib CT', 'Basheer Muhiyudheen', 'Ruksana P', 'Salman Azhari'],
                    options_ml: ['സി ടി സുഹൈബ്', 'ബശീർ മുഹ്യിദ്ദീൻ', 'റുക്സാന പി', 'സൽമാൻ അസ്ഹരി'],
                    correct: 'Suhaib CT',
                    difficulty: 'Medium'
                }
            ]
        }
    ];

    for (const target of targets) {
        const video = await Video.findOne({ title: target.match });
        if (!video) {
            console.log(`  no video matched ${target.match}`);
            continue;
        }
        const removed = await VideoQuestion.deleteMany({ videoId: video._id });
        const docs = await VideoQuestion.create(build(video._id, target.rows));
        console.log(
            `  ${video.title.slice(0, 42)} -> ${docs.length} questions (replaced ${removed.deletedCount})`
        );
    }

    const total = await VideoQuestion.countDocuments();
    const videosWith = (await VideoQuestion.distinct('videoId')).length;
    console.log(`\ntotal video questions: ${total} across ${videosWith} video(s)`);
    await mongoose.disconnect();
}

main().catch(async (err) => {
    console.error('SEED FAILED:', err.message);
    await mongoose.disconnect().catch(() => {});
    process.exit(1);
});
