// multer-compatible multipart parser using the Fetch API's formData().
// Files are buffered in memory (Workers cap request bodies, 100MB on the free
// plan) and handed to storage._handleFile(req, file, cb); the storage engine
// in services/cdnStorageService.js writes them to R2.
class MulterError extends Error {
    constructor(code, field) {
        super(code === 'LIMIT_FILE_SIZE' ? 'File too large' : code);
        this.name = 'MulterError'; this.code = code; this.field = field;
    }
}

function multer(options = {}) {
    const { storage, limits = {}, fileFilter } = options;

    const run = (pick) => async (req, res, next) => {
        const ct = (req.headers['content-type'] || '');
        if (!/multipart\/form-data/i.test(ct)) return next();
        let form;
        try { form = await req._request.formData(); } catch (e) { return next(new MulterError('Malformed multipart body')); }
        const body = {};
        const files = [];
        for (const [name, value] of form.entries()) {
            if (typeof value === 'string') {
                body[name] = name in body ? [].concat(body[name], value) : value;
            } else if (value && typeof value.arrayBuffer === 'function') {
                if (!value.name && value.size === 0) continue; // empty file input
                files.push({ fieldname: name, file: value });
            }
        }
        req.body = body;
        const wanted = files.filter((f) => pick.fields.some((p) => p.name === f.fieldname));
        const unexpected = files.find((f) => !pick.fields.some((p) => p.name === f.fieldname));
        if (unexpected) return next(new MulterError('LIMIT_UNEXPECTED_FILE', unexpected.fieldname));
        const stored = [];
        try {
            for (const { fieldname, file } of wanted) {
                const info = { fieldname, originalname: file.name, mimetype: file.type, size: file.size, encoding: '7bit' };
                if (limits.fileSize && file.size > limits.fileSize) throw new MulterError('LIMIT_FILE_SIZE', fieldname);
                await new Promise((resolve, reject) => {
                    if (!fileFilter) return resolve();
                    fileFilter(req, info, (err, ok) => (err ? reject(err) : ok === false ? reject(new MulterError('FILTERED', fieldname)) : resolve()));
                });
                info.buffer = Buffer.from(await file.arrayBuffer());
                const saved = await new Promise((resolve, reject) => storage._handleFile(req, info, (err, out) => (err ? reject(err) : resolve(out))));
                delete info.buffer;
                stored.push({ ...info, ...saved });
            }
        } catch (e) { return next(e); }
        if (pick.mode === 'single') req.file = stored[0];
        else req.files = pick.mode === 'fields' ? Object.fromEntries(pick.fields.map((p) => [p.name, stored.filter((s) => s.fieldname === p.name)])) : stored;
        if (pick.mode === 'array' && pick.max && stored.length > pick.max) return next(new MulterError('LIMIT_UNEXPECTED_FILE', pick.fields[0].name));
        next();
    };

    return {
        single: (name) => run({ mode: 'single', fields: [{ name }] }),
        array: (name, max) => run({ mode: 'array', fields: [{ name }], max }),
        fields: (fields) => run({ mode: 'fields', fields }),
        none: () => run({ mode: 'none', fields: [] })
    };
}

multer.MulterError = MulterError;
multer.memoryStorage = () => ({ _handleFile: (req, file, cb) => cb(null, { buffer: file.buffer }) });
module.exports = multer;
