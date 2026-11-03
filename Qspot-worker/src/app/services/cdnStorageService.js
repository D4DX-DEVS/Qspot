const multer = require('multer');
const path = require('path');
const bindings = require('../../shims/bindings');

// Uploads go to Cloudflare R2 (binding BUCKET). Files are public through
// R2_PUBLIC_URL when set (a custom domain on the bucket), otherwise the Worker
// itself serves them at /files/<key>.
const CDN_ENABLED = true;

const folder = () => process.env.R2_FOLDER || 'uploads';

// File filter for images/handouts.
const fileFilter = (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|webp|pdf/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
        return cb(null, true);
    }
    cb(new Error('Invalid file type. Only JPEG, PNG, GIF, WEBP, and PDF files are allowed.'));
};

// Student profile photos are deliberately image-only. Keeping this separate
// from the admin image/PDF uploader prevents a learner from storing a PDF as
// an avatar while preserving the existing shared upload limits.
const profileFileFilter = (req, file, cb) => {
    const allowedTypes = /^(jpeg|jpg|png|gif|webp)$/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase().slice(1));
    const mimetype = /^image\/(jpeg|png|gif|webp)$/i.test(file.mimetype);

    if (mimetype && extname) return cb(null, true);
    cb(Object.assign(
        new Error('Invalid profile photo. Only JPEG, PNG, GIF, and WEBP images are allowed.'),
        { status: 400 }
    ));
};

// File filter for video uploads.
const videoFileFilter = (req, file, cb) => {
    const allowedExt = /mp4|webm|mov|m4v/;
    const allowedMime = /video\/(mp4|webm|quicktime|x-m4v)/;
    const extname = allowedExt.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedMime.test(file.mimetype);

    if (mimetype && extname) {
        return cb(null, true);
    }
    cb(new Error('Invalid file type. Only MP4, WEBM, MOV, and M4V video files are allowed.'));
};

// Learner attachments can be audio or images. PDFs remain supported for
// assignments that explicitly allow them, but executable/video uploads are
// rejected before they reach the assignment route.
const assignmentFileFilter = (req, file, cb) => {
    const allowedMime = /^(audio\/(mpeg|mp3|wav|x-wav|mp4|aac|ogg|webm|x-m4a)|image\/(jpeg|png|webp|gif)|application\/pdf|text\/plain)$/i;
    if (allowedMime.test(file.mimetype)) return cb(null, true);
    cb(new Error('Invalid attachment type. Upload an audio recording, image, or PDF file.'));
};

// Multer storage engine writing to R2.
const r2Storage = {
    _handleFile: async function (req, file, cb) {
        const bucket = bindings.bucket;
        if (!bucket) return cb(Object.assign(new Error('File uploads are disabled: R2 bucket is not bound'), { status: 503 }));
        try {
            const key = `${folder()}/${Date.now()}-${Math.round(Math.random() * 1E9)}${path.extname(file.originalname).toLowerCase()}`;
            await bucket.put(key, file.buffer, { httpMetadata: { contentType: file.mimetype } });
            cb(null, { key, location: getCdnUrl(key), size: file.buffer.length });
        } catch (error) {
            cb(error);
        }
    },
    _removeFile: function (req, file, cb) {
        deleteFile(file.key).then(() => cb(null), cb);
    }
};
const customS3Storage = r2Storage;

const limitFrom = (envVar, fallback) => parseInt(process.env[envVar], 10) || fallback;
const build = (filter, envVar, fallback) => multer({
    storage: r2Storage,
    fileFilter: filter,
    limits: { fileSize: limitFrom(envVar, fallback) }
});

// Image / PDF uploads (banners, subject/course covers, speaker photos, handouts).
const upload = build(fileFilter, 'R2_MAX_FILE_SIZE', 5242880);
const profileUpload = build(profileFileFilter, 'R2_MAX_FILE_SIZE', 5242880);

// Document handouts (PDF workbooks, notes) are bigger than the images the main
// uploader is sized for, so they get their own ceiling.
const uploadLarge = build(fileFilter, 'R2_HANDOUT_MAX_FILE_SIZE', 26214400);

// Lesson materials have their own allowlist, including plain-text handouts.
const handoutFileFilter = (req, file, cb) => {
    const types = {
        '.pdf': ['application/pdf'], '.txt': ['text/plain'],
        '.jpg': ['image/jpeg'], '.jpeg': ['image/jpeg'],
        '.png': ['image/png'], '.webp': ['image/webp'], '.gif': ['image/gif']
    };
    const extension = path.extname(file.originalname).toLowerCase();
    if (types[extension]?.includes(file.mimetype.toLowerCase())) return cb(null, true);
    cb(Object.assign(new Error('Choose a PDF, TXT, JPEG, PNG, WEBP, or GIF file.'), { status: 400 }));
};
const handoutUpload = build(handoutFileFilter, 'R2_HANDOUT_MAX_FILE_SIZE', 26214400);

// Video uploads (admin `POST/PUT /api/videos` with a `video` file field).
// shortcut: buffered through the Worker, so capped by the request-body limit
// (100MB free / 200MB paid); move to R2 multipart/presigned upload for larger files.
const uploadVideo = build(videoFileFilter, 'R2_VIDEO_MAX_FILE_SIZE', 100 * 1024 * 1024);

const assignmentUpload = build(assignmentFileFilter, 'R2_ASSIGNMENT_MAX_FILE_SIZE', 25 * 1024 * 1024);

const publicBase = () => (process.env.R2_PUBLIC_URL || '').replace(/\/+$/, '');

// Helper function to get CDN URL
const getCdnUrl = (fileKey) => {
    if (!fileKey) return '';
    const base = publicBase();
    return base ? `${base}/${fileKey}` : `/files/${fileKey}`;
};

// Helper function to delete file from R2
const deleteFile = async (fileKey) => {
    const bucket = bindings.bucket;
    if (!bucket || !fileKey) return { success: false, error: 'R2 bucket not bound' };
    try {
        await bucket.delete(fileKey);
        return { success: true, message: 'File deleted successfully' };
    } catch (error) {
        console.error('Error deleting file from R2:', error);
        return { success: false, error: error.message };
    }
};

// Helper function to check if file exists
const fileExists = async (fileKey) => {
    const bucket = bindings.bucket;
    if (!bucket) return false;
    try {
        return Boolean(await bucket.head(fileKey));
    } catch (error) {
        return false;
    }
};

// Helper function to list files in a folder
const listFiles = async (folderPrefix) => {
    const bucket = bindings.bucket;
    if (!bucket) return { success: false, error: 'R2 bucket not bound' };
    try {
        const data = await bucket.list({ prefix: folderPrefix || folder() });
        return {
            success: true,
            files: data.objects.map((file) => ({
                key: file.key,
                size: file.size,
                lastModified: file.uploaded,
                url: getCdnUrl(file.key)
            }))
        };
    } catch (error) {
        console.error('Error listing files:', error);
        return { success: false, error: error.message };
    }
};

// Helper function to extract file key from a stored file URL
const getFileKeyFromUrl = (url) => {
    if (!url) return null;
    const base = publicBase();
    if (base && url.startsWith(base + '/')) return url.slice(base.length + 1);
    if (url.startsWith('/files/')) return url.slice('/files/'.length);
    return null;
};

module.exports = {
    upload,
    profileUpload,
    uploadLarge,
    handoutUpload,
    customS3Storage,
    uploadVideo,
    assignmentUpload,
    s3Client: null,
    CDN_ENABLED,
    getCdnUrl,
    deleteFile,
    fileExists,
    listFiles,
    getFileKeyFromUrl
};
