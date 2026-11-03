// Holds the Worker's env bindings so the Express-style app code can reach R2
// without threading `env` through every call. Set once per request.
const holder = { env: null };
module.exports = {
    set(env) { holder.env = env; },
    get env() { return holder.env; },
    get bucket() { return holder.env && holder.env.BUCKET; }
};
