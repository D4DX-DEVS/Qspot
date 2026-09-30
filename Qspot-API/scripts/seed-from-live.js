/**
 * Copy the published content from the live QSPOT API into the local database.
 *
 *   node scripts/seed-from-live.js
 *   node scripts/seed-from-live.js --base=https://qspot-api-ldzmy.ondigitalocean.app
 *
 * Copies everything public on the live API: courses, subjects, speakers,
 * videos, notifications, banners, schedules.
 *
 * Deliberately does NOT touch:
 *   - users          live users are admin-only, and the local dev logins must survive
 *   - questions      GET /api/questions now requires a student token (contract v2)
 *   - quiz config    the live quiz window already expired
 *   - quiz questions / attempts  the live endpoint requires a token
 *
 * Documents keep their live _id, so re-running updates in place instead of
 * duplicating, and references (video.subject, video.speaker, subject.courseId)
 * stay correct.
 */
require('dotenv').config();

const mongoose = require('mongoose');
const { ObjectId } = mongoose.Types;

const BASE =
  (process.argv.find((a) => a.startsWith('--base=')) || '').slice('--base='.length) ||
  'https://qspot-api-ldzmy.ondigitalocean.app';

const COLLECTIONS = [
  { path: '/api/courses', collection: 'courses' },
  { path: '/api/subjects', collection: 'subjects' },
  { path: '/api/speakers', collection: 'speakers' },
  { path: '/api/videos', collection: 'videos' },
  { path: '/api/notifications', collection: 'notifications' },
  { path: '/api/banner', collection: 'banners' },
  { path: '/api/schedules', collection: 'schedules' },
];

// Fields the API populates for convenience; the database only stores the id.
const ID_FIELDS = ['subject', 'faculty', 'user', 'speaker', 'courseId'];

const toId = (value) => {
  if (!value) return value;
  const raw = typeof value === 'object' ? value._id : value;
  if (!raw) return null;
  try {
    return new ObjectId(String(raw));
  } catch (e) {
    return value;
  }
};

const normalize = (doc) => {
  const out = { ...doc };
  // The API serialises _id as a string, but the references below are real
  // ObjectIds — storing string ids here would silently break every lookup.
  if (out._id) out._id = toId(out._id);
  for (const field of ID_FIELDS) {
    if (field in out) out[field] = toId(out[field]);
  }
  delete out.isAnswered; // virtual field from the API, never stored
  return out;
};

const fetchJson = async (url) => {
  const res = await fetch(url, { headers: { accept: 'application/json' } });
  if (!res.ok) throw new Error(`${url} -> HTTP ${res.status}`);
  return res.json();
};

async function main() {
  console.log(`source: ${BASE}`);
  await mongoose.connect(process.env.MONGODB_URI);
  const db = mongoose.connection.db;
  console.log(`target: ${mongoose.connection.name}\n`);

  let copied = 0;

  for (const { path, collection } of COLLECTIONS) {
    let payload;
    try {
      payload = await fetchJson(BASE + path);
    } catch (err) {
      console.log(`  ${collection.padEnd(14)} skipped - ${err.message}`);
      continue;
    }

    const rows = Array.isArray(payload) ? payload : payload.items || [];
    const docs = rows.map(normalize);

    if (docs.length === 0) {
      console.log(`  ${collection.padEnd(14)} 0 rows on live - local left as is`);
      continue;
    }

    const before = await db.collection(collection).countDocuments();
    await db.collection(collection).deleteMany({});
    await db.collection(collection).insertMany(docs, { ordered: false });
    console.log(
      `  ${collection.padEnd(14)} ${String(before).padStart(3)} local rows replaced by ${docs.length} from live`
    );
    copied += docs.length;
  }

  console.log('\n--- local totals now ---');
  const wanted = [
    'courses', 'subjects', 'speakers', 'videos', 'notifications', 'banners', 'schedules',
    'questions', 'users', 'quizconfigs', 'quizquestions',
  ];
  for (const collection of wanted) {
    const n = await db.collection(collection).countDocuments();
    console.log(`  ${collection.padEnd(14)} ${n}`);
  }

  console.log(`\ncopied ${copied} documents from live`);
  await mongoose.disconnect();
}

main().catch(async (err) => {
  console.error('SYNC FAILED:', err.message);
  await mongoose.disconnect().catch(() => {});
  process.exit(1);
});
