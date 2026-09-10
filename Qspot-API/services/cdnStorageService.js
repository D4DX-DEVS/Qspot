const { S3Client, DeleteObjectCommand, HeadObjectCommand, ListObjectsV2Command } = require('@aws-sdk/client-s3');
const { Upload } = require('@aws-sdk/lib-storage');
const multer = require('multer');
const path = require('path');

// Check if required environment variables are set
const checkEnvVars = () => {
    const required = ['DO_SPACES_ENDPOINT', 'DO_SPACES_KEY', 'DO_SPACES_SECRET', 'DO_SPACES_BUCKET'];
    const missing = required.filter(key => !process.env[key]);
    if (missing.length > 0) {
        console.warn(`Warning: Missing environment variables: ${missing.join(', ')}`);
        console.warn('CDN functionality will use local storage. Please set up your .env file for cloud storage.');
    }
};

// Initialize environment check
checkEnvVars();

// Configure DigitalOcean Spaces (S3-compatible)
let s3Client;
let upload;

try {
    // Clean the endpoint URL
    let endpoint = process.env.DO_SPACES_ENDPOINT;
    if (!endpoint.startsWith('http')) {
        endpoint = `https://${endpoint}`;
    }
    
    s3Client = new S3Client({
        endpoint: endpoint,
        region: 'us-east-1',
        credentials: {
            accessKeyId: process.env.DO_SPACES_KEY,
            secretAccessKey: process.env.DO_SPACES_SECRET
        },
        forcePathStyle: false
    });
    console.log('S3 client initialized successfully with endpoint:', endpoint);
} catch (error) {
    console.error('Failed to initialize S3 client:', error.message);
    process.exit(1);
}

// File filter function
const fileFilter = (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|webp|pdf/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
        return cb(null, true);
    } else {
        cb(new Error('Invalid file type. Only JPEG, PNG, GIF, WEBP, and PDF files are allowed.'));
    }
};

// Custom storage for AWS SDK v3
const customS3Storage = {
    _handleFile: async function (req, file, cb) {
        if (!s3Client) {
            return cb(new Error('S3 client not initialized'));
        }

        try {
            const folder = process.env.DO_SPACES_FOLDER || 'uploads';
            const fileName = `${folder}/${Date.now()}-${Math.round(Math.random() * 1E9)}${path.extname(file.originalname)}`;
            
            const upload = new Upload({
                client: s3Client,
                params: {
                    Bucket: process.env.DO_SPACES_BUCKET,
                    Key: fileName,
                    Body: file.stream,
                    ACL: 'public-read',
                    ContentType: file.mimetype
                }
            });

            const result = await upload.done();
            
            cb(null, {
                key: fileName,
                location: result.Location,
                bucket: result.Bucket,
                key: result.Key
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

// Configure multer upload with S3 storage
try {
    upload = multer({
        storage: customS3Storage,
        fileFilter: fileFilter,
        limits: {
            fileSize: parseInt(process.env.DO_MAX_FILE_SIZE) || 5242880
        }
    });
} catch (error) {
    console.error('Failed to initialize S3 upload:', error.message);
    process.exit(1);
}

// Helper function to get CDN URL
const getCdnUrl = (fileKey) => {
    const cdnEndpoint = process.env.DO_SPACES_CDN_ENDPOINT;
    if (cdnEndpoint) {
        return `${cdnEndpoint}/${fileKey}`;
    }
    return `https://${process.env.DO_SPACES_BUCKET}.${process.env.DO_SPACES_ENDPOINT}/${fileKey}`;
};

// Helper function to delete file from CDN
const deleteFile = async (fileKey) => {
    if (!s3Client) {
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
            files: data.Contents.map(file => ({
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
    try {
        const cdnEndpoint = process.env.DO_SPACES_CDN_ENDPOINT;
        const spacesEndpoint = `https://${process.env.DO_SPACES_BUCKET}.${process.env.DO_SPACES_ENDPOINT}`;
        
        if (url.startsWith(cdnEndpoint)) {
            return url.replace(`${cdnEndpoint}/`, '');
        } else if (url.startsWith(spacesEndpoint)) {
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
    s3Client,
    getCdnUrl,
    deleteFile,
    fileExists,
    listFiles,
    getFileKeyFromUrl
};

