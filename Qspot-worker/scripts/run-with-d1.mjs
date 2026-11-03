// Runs a Node script from src/app/scripts against the local D1 database
// (the same persisted state `wrangler dev` uses):
//   node scripts/run-with-d1.mjs seed-demo.js --force
import Module, { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { getPlatformProxy } from 'wrangler';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(import.meta.url);
const alias = {
    mongoose: 'mongoose.js', dotenv: 'noop.js', helmet: 'noop.js', cors: 'noop.js', jsonwebtoken: 'jsonwebtoken.js', axios: 'axios.js',
    multer: 'multer.js', 'express-rate-limit': 'express-rate-limit.js', express: 'express.js'
};
const resolve = Module._resolveFilename;
Module._resolveFilename = function (request, ...rest) {
    return alias[request] ? path.join(root, 'src/shims', alias[request]) : resolve.call(this, request, ...rest);
};

const [script, ...args] = process.argv.slice(2);
const { env, dispose } = await getPlatformProxy({ persist: { path: path.join(root, '.wrangler/state/v3') } });
require(path.join(root, 'src/shims/mongoose.js')).__setDb(env.DB);
require(path.join(root, 'src/shims/bindings.js')).set(env);
// Load .dev.vars so process.env matches what the Worker sees.
for (const line of (await import('node:fs')).readFileSync(path.join(root, '.dev.vars'), 'utf8').split(/\r?\n/)) {
    const m = /^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/.exec(line);
    if (m && !(m[1] in process.env)) process.env[m[1]] = m[2].replace(/^"|"$/g, '');
}
process.argv = [process.argv[0], path.join(root, 'src/app/scripts', script), ...args];
const m = require(path.join(root, 'src/shims/mongoose.js'));
m.disconnect = async () => { await dispose(); setTimeout(() => process.exit(0), 100); };
require(path.join(root, 'src/app/scripts', script));
