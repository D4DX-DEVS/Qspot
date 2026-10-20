// Each student sees a quiz question's options in their own random order.
//
// The order is picked once, when the student's quiz session is created, and
// saved in that session, so opening the quiz again shows the same order. The
// app sends the position of the option the student tapped in the order it was
// shown; the submit route turns that back into the position in the stored
// options list before grading. Attempts, results and the admin pages therefore
// always use the stored order.

// True / False keeps its order: "False, True" only confuses.
const isTrueFalse = (type) => /true/i.test(type || '');

// Both lists are shown in the same order, so they must line up. An empty
// Malayalam list is fine (the app shows English then).
const listsLineUp = (optionsEn, optionsMl) =>
    optionsMl.length === 0 || optionsMl.length === optionsEn.length;

const canShuffle = (type, optionsEn, optionsMl) =>
    !isTrueFalse(type) && optionsEn.length > 1 && listsLineUp(optionsEn, optionsMl);

// A random order of 0..length-1 (Fisher-Yates).
const shuffledOrder = (length) => {
    const order = Array.from({ length }, (_, i) => i);
    for (let i = order.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [order[i], order[j]] = [order[j], order[i]];
    }
    return order;
};

// The order saved for this question, or null to use the stored order: no
// order saved (True / False, or a session from before options were shuffled),
// or the options were edited since and the saved order no longer fits.
const savedOrder = (session, questionId, optionsEn, optionsMl) => {
    const entry = (session?.optionOrders || []).find((o) => String(o.questionId) === String(questionId));
    if (!entry || !listsLineUp(optionsEn, optionsMl)) return null;
    const order = Array.from(entry.order || [], Number);
    const fits = order.length === optionsEn.length
        && order.every((i) => Number.isInteger(i) && i >= 0 && i < order.length)
        && new Set(order).size === order.length;
    return fits ? order : null;
};

const inShownOrder = (options, order) =>
    order && options.length === order.length ? order.map((i) => options[i]) : options;

// Shown position -> stored position. Anything outside the list is left as is.
const storedIndex = (shownIndex, order) =>
    order && shownIndex >= 0 && shownIndex < order.length ? order[shownIndex] : shownIndex;

module.exports = { canShuffle, shuffledOrder, savedOrder, inShownOrder, storedIndex };
