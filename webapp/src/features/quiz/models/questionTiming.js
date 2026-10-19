// How long one question took (mobile-app/lib/screens/quiz/model/question_timing.dart).
// The server receives only the time taken; the rest stays on the device to run
// the question's countdown. Times are milliseconds since the epoch. Immutable:
// every change returns a new value, so the saved copy is always complete.
export class QuestionTiming {
  constructor({ firstShownAt = null, visibleSince = null, spentMs = 0, answerSpentMs = null, timedOut = false } = {}) {
    // Starts the question's countdown.
    this.firstShownAt = firstShownAt
    // Set while the question is on screen with the page in front; the time
    // since then is not yet in spentMs.
    this.visibleSince = visibleSince
    this.spentMs = spentMs
    // Time on screen when the final answer was picked.
    this.answerSpentMs = answerSpentMs
    this.timedOut = timedOut
    Object.freeze(this)
  }

  static empty = new QuestionTiming()

  // Time taken to answer; for an unanswered question, its time on screen
  // (the full limit when its time ran out).
  get timeTakenMs() {
    return this.answerSpentMs ?? this.spentMs
  }

  // Milliseconds on screen up to [now], including the visit in progress.
  spentMsAt(now) {
    return this.spentMs + (this.visibleSince == null ? 0 : Math.max(0, now - this.visibleSince))
  }

  #with(changes) {
    return new QuestionTiming({
      firstShownAt: this.firstShownAt,
      visibleSince: this.visibleSince,
      spentMs: this.spentMs,
      answerSpentMs: this.answerSpentMs,
      timedOut: this.timedOut,
      ...changes,
    })
  }

  // The student moved to this question.
  shown(now) {
    return this.#with({ firstShownAt: this.firstShownAt ?? now, visibleSince: now })
  }

  // The student moved away, or the page went to the background.
  hidden(now) {
    return this.visibleSince == null ? this : this.#with({ spentMs: this.spentMsAt(now), visibleSince: null })
  }

  // The page came back to the front with this question on screen.
  resumed(now) {
    return this.visibleSince == null ? this.#with({ visibleSince: now }) : this
  }

  // An option was picked. Picking the option already chosen changes nothing.
  answered(now, { previous, choice }) {
    return previous === choice ? this : this.#with({ answerSpentMs: this.spentMsAt(now) })
  }

  // The countdown reached [deadline]: the question took its full [limitMs].
  expiredAt(deadline, limitMs = null) {
    const stopped = this.hidden(deadline)
    return stopped.#with({ spentMs: limitMs ?? stopped.spentMs, timedOut: true })
  }

  // What the server receives for this question: seconds, one decimal.
  toSubmission() {
    return { duration: Math.round(this.timeTakenMs / 100) / 10 }
  }

  toJSON() {
    const iso = (ms) => (ms == null ? null : new Date(ms).toISOString())
    return {
      firstShownAt: iso(this.firstShownAt),
      visibleSince: iso(this.visibleSince),
      spentMs: this.spentMs,
      answerSpentMs: this.answerSpentMs,
      timedOut: this.timedOut,
    }
  }

  static fromJSON(json) {
    if (!json || typeof json !== 'object') return QuestionTiming.empty
    const date = (key) => {
      const ms = Date.parse(json[key] ?? '')
      return Number.isNaN(ms) ? null : ms
    }
    const int = (v) => (Number.isInteger(v) ? Math.max(0, v) : null)
    return new QuestionTiming({
      firstShownAt: date('firstShownAt'),
      visibleSince: date('visibleSince'),
      spentMs: int(json.spentMs) ?? 0,
      answerSpentMs: int(json.answerSpentMs),
      timedOut: json.timedOut === true,
    })
  }
}
