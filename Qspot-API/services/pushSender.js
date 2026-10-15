// Sends push notifications to phones. Chosen with the PUSH_PROVIDER
// environment variable; 'none' (the default) sends nothing, and learners
// still find every notification in the app's notification list. To connect
// a service later (for example Firebase Cloud Messaging), add an entry to
// `providers` with send(tokens, message) and set PUSH_PROVIDER to its name.
const providers = {
    none: { send: async () => ({ sent: 0 }) }
};

const pickProvider = (name = process.env.PUSH_PROVIDER) =>
    providers[String(name || 'none').trim().toLowerCase()] || providers.none;

// message = { title, body, data: { kind, targetKind, targetId, notificationId } }
// Never throws: a failed push must not undo the inbox item.
const sendPush = async (tokens, message, provider = pickProvider()) => {
    if (!Array.isArray(tokens) || tokens.length === 0) return { sent: 0 };
    try {
        return await provider.send(tokens, message);
    } catch (error) {
        console.error('Push failed:', error);
        return { sent: 0, error: error.message };
    }
};

module.exports = { sendPush, pickProvider, providers };
