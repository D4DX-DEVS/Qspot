// Admin search boxes match the typed text as plain text: symbols like "+" or
// "(" are not pattern syntax, so they never break the search.
const escapeRegExp = (value) => String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const textMatch = (value) => new RegExp(escapeRegExp(String(value).trim()), 'i');

module.exports = { escapeRegExp, textMatch };
