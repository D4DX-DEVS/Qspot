// Lets `node --test` load the app code with the Worker shims standing in for
// mongoose, express-rate-limit, etc. (same mapping as wrangler.toml [alias]).
const Module = require('node:module');
const path = require('node:path');
const alias = { mongoose: 'mongoose.js', express: 'express.js', 'express-rate-limit': 'express-rate-limit.js', jsonwebtoken: 'jsonwebtoken.js', multer: 'multer.js', axios: 'axios.js', helmet: 'noop.js', dotenv: 'noop.js', cors: 'noop.js' };
const resolve = Module._resolveFilename;
Module._resolveFilename = function (request, ...rest) {
    return alias[request] ? path.join(__dirname, '../src/shims', alias[request]) : resolve.call(this, request, ...rest);
};
