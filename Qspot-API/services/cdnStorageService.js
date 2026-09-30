const { S3Client, DeleteObjectCommand, HeadObjectCommand, ListObjectsV2Command } = require('@aws-sdk/client-s3');
const { Upload } = require('@aws-sdk/lib-storage');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { PassThrough } = require('stream');

// Whether CDN uploads are usable at all. When the required env vars are not
// set (e.g. local dev, CI, or a test run) the service disables uploads and
// logs a warning instead of crashing the process — the rest of the API must
// keep working without image/video upload.
const REQUIRED_ENV = ['DO_SPACES_ENDPOINT', 'DO_SPACES_KEY', 'DO_SPACES_SECRET', 'DO_SPACES_BUCKET'];
const missingEnv = REQUIRED_ENV.filter((key) => !process.env[key]);
const CDN_ENABLED = missingEnv.length === 0;

if (!CDN_ENABLED) {
    console.warn(`CDN storage disabled: missing env vars ${missingEnv.join(', ')}. Uploads will return 503.`);
}

let s3Client = null;

if (CDN_ENABLED) {
    try {
        let endpoint = process.env.DO_SPACES_ENDPOINT;
        if (!endpoint.startsWith('http')) {
            endpoint = `https://${endpoint}`;
        }

        s3Client = new S3Client({
            endpoint,
            region: 'us-east-1',
            credentials: {
                accessKeyId: process.env.DO_SPACES_KEY,
                secretAccessKey: process.env.DO_SPACES_SECRET
            },
            forcePathStyle: false
        });
        console.log('S3 client initialized successfully with endpoint:', endpoint);
    } catch (error) {
        console.error('Failed to initialize S3 client, disabling CDN uploads:', error.message);
        s3Client = null;
    }
}

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

// Custom storage for AWS SDK v3. Only used when CDN_ENABLED — callers must
// check that first and short-circuit with a 503 otherwise.
const customS3Storage = {
    _handleFile: async function (req, file, cb) {
        if (!s3Client) {
            return cb(new Error('CDN storage is not configured'));
        }

        try {
            const folder = process.env.DO_SPACES_FOLDER || 'uploads';
            const fileName = `${folder}/${Date.now()}-${Math.round(Math.random() * 1E9)}${path.extname(file.originalname)}`;
            const passThrough = new PassThrough();
            let size = 0;
            file.stream.on('data', (chunk) => {
                size += chunk.length;
            });
            file.stream.pipe(passThrough);

            const uploader = new Upload({
                client: s3Client,
                params: {
                    Bucket: process.env.DO_SPACES_BUCKET,
                    Key: fileName,
                    Body: passThrough,
                    ACL: 'public-read',
                    ContentType: file.mimetype
                }
            });

            const result = await uploader.done();

            cb(null, {
                key: result.Key || fileName,
                location: result.Location,
                bucket: result.Bucket,
                size
            });
        } catch (error) {
            cb(error);
        }
    },
    _removeFile: function (req, file, cb) {
        // No cleanup needed for S3
        cb(null);
    }
};

// A middleware that always rejects with a JSON-friendly error, used in place
// of a real multer instance when the CDN is not configured.
const disabledUpload = () => (req, res, next) => {
    next(Object.assign(new Error('File uploads are disabled: CDN storage is not configured'), { status: 503 }));
};

const buildUploader = (fileFilterFn, limitEnvVar, defaultLimit) => {
    if (!CDN_ENABLED) {
        return { single: disabledUpload, array: disabledUpload, fields: disabledUpload };
    }
    try {
        return multer({
            storage: customS3Storage,
            fileFilter: fileFilterFn,
            limits: {
                fileSize: parseInt(process.env[limitEnvVar], 10) || defaultLimit
            }
        });
    } catch (error) {
        console.error(`Failed to initialize uploader for ${limitEnvVar}:`, error.message);
        return { single: disabledUpload, array: disabledUpload, fields: disabledUpload };
    }
};

// Image / PDF uploads (banners, subject/course covers, speaker photos, handouts).
const upload = buildUploader(fileFilter, 'DO_MAX_FILE_SIZE', 5242880);

// Document handouts (PDF workbooks, notes) are bigger than the images the main
// uploader is sized for, so they get their own ceiling.
const uploadLarge = buildUploader(fileFilter, 'DO_HANDOUT_MAX_FILE_SIZE', 26214400);

// Video uploads (admin `POST/PUT /api/videos` with a `video` file field).
const uploadVideo = buildUploader(videoFileFilter, 'DO_VIDEO_MAX_FILE_SIZE', 524288000);

const localAssignmentStorage = multer.diskStorage({
    destination: (req, file, cb) => {
        const directory = path.join(__dirname, '..', 'uploads', 'assignments');
        fs.mkdirSync(directory, { recursive: true });
        cb(null, directory);
    },
    filename: (req, file, cb) => {
        const safeName = path.basename(file.originalname).replace(/[^a-zA-Z0-9._-]/g, '_');
        cb(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}-${safeName}`);
    }
});

// The local fallback keeps the complete submission flow usable without cloud
// credentials. Production uses the same endpoint with CDN-backed storage.
const assignmentUpload = CDN_ENABLED
    ? multer({
        storage: customS3Storage,
        fileFilter: assignmentFileFilter,
        limits: { fileSize: parseInt(process.env.DO_ASSIGNMENT_MAX_FILE_SIZE, 10) || 25 * 1024 * 1024 }
    })
    : multer({
        storage: localAssignmentStorage,
        fileFilter: assignmentFileFilter,
        limits: { fileSize: parseInt(process.env.DO_ASSIGNMENT_MAX_FILE_SIZE, 10) || 25 * 1024 * 1024 }
    });

// Helper function to get CDN URL
const getCdnUrl = (fileKey) => {
    if (!fileKey) return '';
    const cdnEndpoint = process.env.DO_SPACES_CDN_ENDPOINT;
    if (cdnEndpoint) {
        return `${cdnEndpoint}/${fileKey}`;
    }
    if (!process.env.DO_SPACES_BUCKET || !process.env.DO_SPACES_ENDPOINT) {
        return fileKey;
    }
    return `https://${process.env.DO_SPACES_BUCKET}.${process.env.DO_SPACES_ENDPOINT}/${fileKey}`;
};

// Helper function to delete file from CDN
const deleteFile = async (fileKey) => {
    if (!s3Client || !fileKey) {
        return { success: false, error: 'S3 client not initialized' };
    }

    try {
        const command = new DeleteObjectCommand({
            Bucket: process.env.DO_SPACES_BUCKET,
            Key: fileKey
        });
        await s3Client.send(command);
        return { success: true, message: 'File deleted successfully' };
    } catch (error) {
        console.error('Error deleting file from CDN:', error);
        return { success: false, error: error.message };
    }
};

// Helper function to check if file exists
const fileExists = async (fileKey) => {
    if (!s3Client) {
        return false;
    }

    try {
        const command = new HeadObjectCommand({
            Bucket: process.env.DO_SPACES_BUCKET,
            Key: fileKey
        });
        await s3Client.send(command);
        return true;
    } catch (error) {
        return false;
    }
};

// Helper function to list files in a folder
const listFiles = async (folderPrefix) => {
    if (!s3Client) {
        return { success: false, error: 'S3 client not initialized' };
    }

    try {
        const command = new ListObjectsV2Command({
            Bucket: process.env.DO_SPACES_BUCKET,
            Prefix: folderPrefix || process.env.DO_SPACES_FOLDER
        });
        const data = await s3Client.send(command);
        return {
            success: true,
            files: (data.Contents || []).map((file) => ({
                key: file.Key,
                size: file.Size,
                lastModified: file.LastModified,
                url: getCdnUrl(file.Key)
            }))
        };
    } catch (error) {
        console.error('Error listing files:', error);
        return { success: false, error: error.message };
    }
};

// Helper function to extract file key from CDN URL
const getFileKeyFromUrl = (url) => {
    if (!url) return null;
    try {
        const cdnEndpoint = process.env.DO_SPACES_CDN_ENDPOINT;
        const spacesEndpoint =
            process.env.DO_SPACES_BUCKET && process.env.DO_SPACES_ENDPOINT
                ? `https://${process.env.DO_SPACES_BUCKET}.${process.env.DO_SPACES_ENDPOINT}`
                : null;

        if (cdnEndpoint && url.startsWith(cdnEndpoint)) {
            return url.replace(`${cdnEndpoint}/`, '');
        }
        if (spacesEndpoint && url.startsWith(spacesEndpoint)) {
            return url.replace(`${spacesEndpoint}/`, '');
        }
        return null;
    } catch (error) {
        console.error('Error extracting file key:', error);
        return null;
    }
};

module.exports = {
    upload,
    uploadLarge,
    uploadVideo,
    assignmentUpload,
    s3Client,
    CDN_ENABLED,
    getCdnUrl,
    deleteFile,
    fileExists,
    listFiles,
    getFileKeyFromUrl
};
