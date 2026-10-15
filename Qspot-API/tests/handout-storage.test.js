const test = require('node:test');
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const path = require('node:path');
process.env.DO_SPACES_ENDPOINT = 'https://example.invalid';
process.env.DO_SPACES_BUCKET = 'test';
process.env.DO_SPACES_KEY = 'test';
process.env.DO_SPACES_SECRET = 'test';
const { s3Client, customS3Storage } = require('../services/cdnStorageService');

test('Multer partial-batch cleanup deletes the accepted Spaces object', async () => {
    const original = s3Client.send;
    let sent;
    s3Client.send = async (command) => { sent = command; };
    try {
        await new Promise((resolve, reject) => customS3Storage._removeFile({}, {
            bucket: 'test', key: 'uploads/accepted.pdf'
        }, (error) => error ? reject(error) : resolve()));
        assert.equal(sent.constructor.name, 'DeleteObjectCommand');
        assert.deepEqual(sent.input, { Bucket: 'test', Key: 'uploads/accepted.pdf' });
    } finally { s3Client.send = original; }
});

test('Spaces cleanup reports storage failure to Multer', async () => {
    const original = s3Client.send;
    s3Client.send = async () => { throw new Error('storage failed'); };
    try {
        await assert.rejects(new Promise((resolve, reject) => customS3Storage._removeFile({}, {
            bucket: 'test', key: 'uploads/accepted.pdf'
        }, (error) => error ? reject(error) : resolve())), /storage failed/);
    } finally { s3Client.send = original; }
});

test('production without Spaces keeps local handout upload disabled', () => {
    const env = { ...process.env, NODE_ENV: 'production' };
    for (const key of ['DO_SPACES_ENDPOINT', 'DO_SPACES_BUCKET', 'DO_SPACES_KEY', 'DO_SPACES_SECRET']) delete env[key];
    const result = spawnSync(process.execPath, ['-e', "require('./services/cdnStorageService').handoutUpload.array('files',10)({}, {}, error => { if (error.status !== 503) process.exit(1); });"], {
        cwd: path.join(__dirname, '..'), env, encoding: 'utf8'
    });
    assert.equal(result.status, 0);
});
