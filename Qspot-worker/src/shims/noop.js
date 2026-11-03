// Stand-in for packages that do nothing useful on Workers (helmet, dotenv, cors):
// security headers and CORS are applied once in src/index.js.
const passthrough = () => (req, res, next) => next();
module.exports = passthrough;
module.exports.config = () => ({});
module.exports.default = passthrough;
