/** Local-only, additive demo. Existing lessons are never edited or deleted. */
require('dotenv').config({ quiet: true });
const fs = require('node:fs/promises');
const path = require('node:path');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const Subject = require('../models/subject');
const Video = require('../models/videos');

const TITLE = 'Demo - Learn materials preview';
const API = process.env.LOCAL_API_URL || 'http://localhost:5001';
const fixtures = path.join(__dirname, 'fixtures', 'learn-demo');

async function main() {
    if (process.env.NODE_ENV === 'production' ||
        !/^mongodb:\/\/(localhost|127\.0\.0\.1)(:\d+)?\//.test(process.env.MONGODB_URI || '') ||
        !['localhost', '127.0.0.1'].includes(new URL(API).hostname)) {
        throw new Error('This demo can only run against a local API and local MongoDB.');
    }
    await mongoose.connect(process.env.MONGODB_URI);
    const subject = await Subject.findOne({ name: /quran recitation/i, isPublished: { $ne: false } });
    if (!subject) throw new Error('Seed the local courses first; Quran Recitation was not found.');
    let lesson = await Video.findOne({ title: TITLE, subject: subject._id });
    if (!lesson) {
        const source = await Video.findOne({ subject: subject._id, title: { $ne: TITLE } });
        if (!source) throw new Error('Add a local Quran Recitation lesson first.');
        const last = await Video.findOne({ subject: subject._id }).sort({ order: -1 });
        lesson = await Video.create({
            title: TITLE, subject: subject._id, video: source.video,
            description: 'Demo content showing plain text, an image, a PDF, and a TXT attachment.',
            order: (last?.order || 0) + 1, isPublished: true,
            learnText: 'Welcome to the sample Learn section. Read this short note, explore the practice graphic, and open the checklist below. These materials are examples for preview, not official teaching content.',
            learnPoints: ['Read the note at your own pace.', 'Tap the image to open it.', 'Open the PDF checklist or text file.'],
            practiceEnabled: false
        });
    }
    const token = jwt.sign({ role: 'admin' }, process.env.JWT_SECRET, { expiresIn: '5m' });
    const samples = [
        ['learning-routine.png', 'Sample - Learning routine', 'image/png'],
        ['practice-checklist.pdf', 'Sample - Practice checklist', 'application/pdf'],
        ['practice-notes.txt', 'Sample - Practice notes', 'text/plain']
    ];
    const missing = samples.filter(([, title]) => !lesson.downloads.some((item) => item.title === title));
    if (missing.length) {
        const form = new FormData();
        for (const [filename, , type] of missing) {
            form.append('files', new Blob([await fs.readFile(path.join(fixtures, filename))], { type }), filename);
        }
        form.append('titles', JSON.stringify(missing.map(([, title]) => title)));
        const result = await fetch(`${API}/api/videos/${lesson.id}/files`, {
            method: 'POST', headers: { Authorization: `Bearer ${token}` }, body: form
        });
        if (!result.ok) throw new Error(`Demo upload failed (${result.status}): ${(await result.json()).message}`);
    }
    const response = await fetch(`${API}/api/videos/${lesson.id}`);
    if (!response.ok) throw new Error('The demo lesson could not be read back.');
    const saved = await response.json();
    for (const item of saved.downloads) {
        const file = await fetch(new URL(item.url, API));
        if (!file.ok) throw new Error(`The sample file could not be opened: ${item.title}`);
        console.log(`${item.title}: ${file.headers.get('content-type')}`);
    }
    console.log(`Ready: Learn > ${subject.name} > ${TITLE} > Learn`);
    console.log(`Lesson ID: ${lesson.id}`);
}

main().catch((error) => { console.error(error.message); process.exitCode = 1; })
    .finally(() => mongoose.disconnect());
