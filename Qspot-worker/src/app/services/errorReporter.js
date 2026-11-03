// Where server errors go. Chosen with the ERROR_REPORTER environment
// variable; 'none' (the default) keeps today's behaviour of logging to the
// console only. To connect a service later (Sentry, Firebase, ...), add an
// entry to `reporters` with a captureException(error, context) function and
// set ERROR_REPORTER to its name.
const reporters = {
    none: { captureException: () => {} }
};

const pickReporter = (name = process.env.ERROR_REPORTER) =>
    reporters[String(name || 'none').trim().toLowerCase()] || reporters.none;

// Logs the error and hands it to the chosen reporter. Never throws: a broken
// reporter must not turn one error into two.
const reportError = (error, context = {}, reporter = pickReporter()) => {
    console.error(context.label || 'Unhandled error:', error);
    try {
        reporter.captureException(error, context);
    } catch (reporterError) {
        console.error('Error reporter failed:', reporterError);
    }
};

module.exports = { reportError, pickReporter, reporters };
