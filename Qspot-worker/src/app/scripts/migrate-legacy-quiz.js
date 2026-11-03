/**
 * One-time migration for the "legacy quiz" (Option B: quiz list in app).
 *
 * Before this round, exactly one QuizConfig document could exist without a
 * title (the original single-quiz feature). Now `title` is required on every
 * QuizConfig, and quiz questions with a null `quizId` are orphaned unless
 * they get attached to that same legacy document.
 *
 * This script:
 *   1. Finds any QuizConfig with a missing/null/empty title and sets
 *      title = 'Legacy Quiz' (first match only; logs a warning if more than
 *      one such document exists, which should never happen).
 *   2. Finds any QuizQuestion with quizId == null and assigns it to that
 *      legacy quiz's _id.
 *
 * Safe to re-run: it is a no-op once every QuizConfig has a title and no
 * QuizQuestion has a null quizId.
 *
 *   node scripts/migrate-legacy-quiz.js
 */
require('dotenv').config();

const mongoose = require('mongoose');

async function main() {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('connected:', mongoose.connection.name);

    const db = mongoose.connection.db;
    const quizConfigs = db.collection('quizconfigs');
    const quizQuestions = db.collection('quizquestions');

    const untitled = await quizConfigs
        .find({ $or: [{ title: { $exists: false } }, { title: null }, { title: '' }] })
        .toArray();

    if (untitled.length === 0) {
        console.log('no untitled quiz configuration found — nothing to migrate');
    } else {
        if (untitled.length > 1) {
            console.warn(`warning: ${untitled.length} untitled quiz configs found, only the first will be titled/kept`);
        }
        const legacy = untitled[0];
        await quizConfigs.updateOne({ _id: legacy._id }, { $set: { title: 'Legacy Quiz' } });
        console.log(`titled legacy quiz ${legacy._id} -> "Legacy Quiz"`);

        const orphanResult = await quizQuestions.updateMany(
            { $or: [{ quizId: { $exists: false } }, { quizId: null }] },
            { $set: { quizId: legacy._id } }
        );
        console.log(`assigned ${orphanResult.modifiedCount} orphaned quiz question(s) to the legacy quiz`);
    }

    // Any other untitled configs beyond the first: title them uniquely too, so
    // the now-required `title` field never breaks validation on save.
    for (let i = 1; i < untitled.length; i++) {
        const extra = untitled[i];
        await quizConfigs.updateOne({ _id: extra._id }, { $set: { title: `Legacy Quiz ${i + 1}` } });
        console.log(`titled extra untitled quiz ${extra._id} -> "Legacy Quiz ${i + 1}"`);
    }

    console.log('migration complete');
    await mongoose.disconnect();
}

main().catch(async (err) => {
    console.error('MIGRATION FAILED:', err.message);
    await mongoose.disconnect().catch(() => {});
    process.exit(1);
});
