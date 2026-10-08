/**
 * Stores every class as the bare number ("8"), never "Class 8".
 *
 * The app registers students with the bare number and shows "Class 8" by
 * itself, and every class match on the server is an exact string compare.
 * A "Class 8" stored anywhere therefore never matches a real student, and the
 * admin panel and app show it as "Class Class 8".
 *
 * Rewrites values that are exactly "Class <number>" (any case, optional
 * section letter, e.g. "class 10a") in:
 *   users.class, schedules.class, assignments.class, questions.class,
 *   quizconfigs.allowedClasses[], quizconfigs.certificate.eligibleClasses[]
 * Anything else ("8", "Faculty", "Hifz batch") is left as it is.
 *
 * Safe to re-run: it is a no-op once nothing matches.
 *
 *   node scripts/normalize-class-values.js --dry-run   # report only
 *   node scripts/normalize-class-values.js
 */
require('dotenv').config();

const mongoose = require('mongoose');

const DRY_RUN = process.argv.includes('--dry-run');
const PREFIXED = /^\s*class\s*(\d+\s*[a-z]?)\s*$/i;

// "Class 8" -> "8"; returns the value unchanged when it is not that shape.
const bare = (value) => {
    if (typeof value !== 'string') return value;
    const match = value.match(PREFIXED);
    return match ? match[1].replace(/\s+/g, '') : value;
};

const prefixedFilter = { $regex: PREFIXED.source, $options: 'i' };

async function normalizeField(db, collection, field) {
    const docs = await db.collection(collection)
        .find({ [field]: prefixedFilter }, { projection: { [field]: 1 } })
        .toArray();
    const ops = docs.map((doc) => ({
        updateOne: { filter: { _id: doc._id }, update: { $set: { [field]: bare(doc[field]) } } }
    }));
    docs.slice(0, 5).forEach((doc) => console.log(`  ${collection}.${field}: ${JSON.stringify(doc[field])} -> ${JSON.stringify(bare(doc[field]))}`));
    if (!DRY_RUN && ops.length) await db.collection(collection).bulkWrite(ops);
    return ops.length;
}

async function normalizeArray(db, collection, path) {
    const docs = await db.collection(collection)
        .find({ [path]: prefixedFilter }, { projection: { [path]: 1 } })
        .toArray();
    const read = (doc) => path.split('.').reduce((value, key) => value?.[key], doc) || [];
    const ops = docs.map((doc) => {
        // Map, then drop duplicates ("8" and "Class 8" both present).
        const next = [...new Set(read(doc).map(bare))];
        console.log(`  ${collection}.${path}: ${JSON.stringify(read(doc))} -> ${JSON.stringify(next)}`);
        return { updateOne: { filter: { _id: doc._id }, update: { $set: { [path]: next } } } };
    });
    if (!DRY_RUN && ops.length) await db.collection(collection).bulkWrite(ops);
    return ops.length;
}

async function main() {
    await mongoose.connect(process.env.MONGODB_URI);
    const db = mongoose.connection.db;
    console.log(`connected: ${mongoose.connection.name}${DRY_RUN ? ' (dry run, nothing is written)' : ''}`);

    const counts = {
        'users.class': await normalizeField(db, 'users', 'class'),
        'schedules.class': await normalizeField(db, 'schedules', 'class'),
        'assignments.class': await normalizeField(db, 'assignments', 'class'),
        'questions.class': await normalizeField(db, 'questions', 'class'),
        'quizconfigs.allowedClasses': await normalizeArray(db, 'quizconfigs', 'allowedClasses'),
        'quizconfigs.certificate.eligibleClasses': await normalizeArray(db, 'quizconfigs', 'certificate.eligibleClasses')
    };

    console.log(DRY_RUN ? 'would update:' : 'updated:');
    Object.entries(counts).forEach(([field, count]) => console.log(`  ${field}: ${count}`));
    await mongoose.disconnect();
}

main().catch(async (error) => {
    console.error('class normalization failed:', error);
    await mongoose.disconnect().catch(() => {});
    process.exit(1);
});
