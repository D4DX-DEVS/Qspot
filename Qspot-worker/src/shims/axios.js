// Tiny axios replacement on fetch(): get/post/put/delete/request, {data,status}
// results, and axios-style errors (error.response) for non-2xx.
async function request(config) {
    const { url, method = 'get', data, headers = {}, params, timeout, validateStatus } = config;
    const u = new URL(url);
    if (params) Object.entries(params).forEach(([k, v]) => u.searchParams.set(k, v));
    const h = new Headers(headers);
    let body;
    if (data !== undefined && method.toLowerCase() !== 'get') {
        if (typeof data === 'string' || data instanceof URLSearchParams) body = data;
        else { body = JSON.stringify(data); if (!h.has('content-type')) h.set('content-type', 'application/json'); }
    }
    const res = await fetch(u, { method: method.toUpperCase(), headers: h, body, signal: timeout ? AbortSignal.timeout(timeout) : undefined });
    const text = await res.text();
    let parsed = text;
    try { parsed = text ? JSON.parse(text) : text; } catch { /* keep text */ }
    const out = { data: parsed, status: res.status, statusText: res.statusText, headers: Object.fromEntries(res.headers), config };
    if (!(validateStatus ? validateStatus(res.status) : res.ok)) {
        const err = new Error(`Request failed with status code ${res.status}`);
        err.response = out;
        err.isAxiosError = true;
        throw err;
    }
    return out;
}
const axios = (config) => request(config);
for (const m of ['get', 'delete', 'head']) axios[m] = (url, config = {}) => request({ ...config, url, method: m });
for (const m of ['post', 'put', 'patch']) axios[m] = (url, data, config = {}) => request({ ...config, url, data, method: m });
axios.request = request;
module.exports = axios;
module.exports.default = axios;
