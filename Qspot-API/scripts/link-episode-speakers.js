/**
 * Link episodes to the faculty member who presents them.
 *
 * The imported episode titles carry the speaker as the last "|" segment
 * (e.g. "Episode 30 | <topic> | <speaker in Malayalam>"), so the table below
 * translates those names into the speaker records.
 *
 *   node scripts/link-episode-speakers.js --dry-run
 *   node scripts/link-episode-speakers.js
 */
require('dotenv').config();
const mongoose = require('mongoose');
const Video = require('../models/videos');
const Speaker = require('../models/speakers');

// Every spelling that shows up in the imported titles, mapped to the speaker
// record it belongs to. Malayalam first, then the Latin variants.
const TITLE_ALIASES = {
    '\u0d2c\u0d36\u0d40\u0d7c \u0d2e\u0d41\u0d39\u0d4d\u200d\u0d2f\u0d3f\u0d26\u0d4d\u0d26\u0d40\u0d7b': 'Basheer Muhiyudheen',
    'BASHEER MUHIYUDHEEN': 'Basheer Muhiyudheen',
    '\u0d38\u0d3f \u0d1f\u0d3f \u0d38\u0d41\u0d39\u0d48\u0d2c\u0d4d': 'Suhaib CT',
    'SUHAIB CT': 'Suhaib CT',
    '\u0d38\u0d41\u0d32\u0d48\u0d2e\u0d3e\u0d7b \u0d05\u0d38\u0d4d\u0d39\u0d30\u0d3f': 'Salman Azhari',
    'SULAIMAN AZHARI': 'Salman Azhari',
    'SALMAN AZHARI': 'Salman Azhari',
    '\u0d31\u0d41\u0d15\u0d4d\u200d\u0d38\u0d3e\u0d28 \u0d2a\u0d3f': 'Ruksana P',
    'RUKSANA P': 'Ruksana P',
    '\u0d05\u0d2b\u0d4d\u0d30 \u0d36\u0d3f\u0d39\u0d3e\u0d2c\u0d4d': 'Afra Shihab',
    'AFRA SHIHAB': 'Afra Shihab'
};

const normalize = (value) =>
    String(value || '')
        // Malayalam text mixes zero-width joiners and non-joiners; both are
        // invisible but break string comparison, so drop them.
        .replace(/[\u200c\u200d]/g, '')
        .replace(/\s+/g, ' ')
        .trim()
        .toLowerCase();

const findAlias = (title) => {
    const haystack = normalize(title);
    // Longest alias first, so "BASHEER MUHIYUDHEEN" wins over a bare surname.
    return Object.keys(TITLE_ALIASES)
        .sort((a, b) => b.length - a.length)
        .find((alias) => haystack.includes(normalize(alias)));
};

const main = async () => {
    const dryRun = process.argv.includes('--dry-run');

    await mongoose.connect(
        process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/qspot'
    );

    const speakers = await Speaker.find();
    const byName = new Map(
        speakers.map((speaker) => [normalize(speaker.name), speaker])
    );

    const videos = await Video.find();
    const updates = [];
    const unmatched = [];

    for (const video of videos) {
        const hit = findAlias(video.title);

        if (!hit) {
            unmatched.push(video.title);
            continue;
        }

        const speaker = byName.get(normalize(TITLE_ALIASES[hit]));
        if (!speaker) {
            unmatched.push(video.title);
            continue;
        }
        if (String(video.speaker || '') === String(speaker._id)) continue;

        updates.push({ video, speaker });
    }

    console.log(`episodes: ${videos.length}`);
    console.log(`will link: ${updates.length}`);
    for (const { video, speaker } of updates) {
        console.log(`  ${video.title}  ->  ${speaker.name}`);
    }
    console.log(`no faculty named in the title: ${unmatched.length}`);

    if (dryRun) {
        console.log('\n(dry run - nothing written)');
    } else {
        for (const { video, speaker } of updates) {
            video.speaker = speaker._id;
            await video.save();
        }
        console.log(`\nlinked ${updates.length} episodes.`);
    }

    await mongoose.disconnect();
};

main().catch((error) => {
    console.error('Failed:', error.message);
    process.exit(1);
});
