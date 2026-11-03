// Switch for new student sign-ups (POST /api/user/register). While false the
// API turns every registration away, whatever app version sends it. Set it
// back to true and deploy to reopen.
const REGISTRATION_OPEN = false;

module.exports = { REGISTRATION_OPEN };
