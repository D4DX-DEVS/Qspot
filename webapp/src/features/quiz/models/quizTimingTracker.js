import { QuestionTiming } from './questionTiming'

// Keeps the clock for one quiz: per-question timings and the deadlines of the
// whole-quiz and per-question countdowns
// (mobile-app/lib/screens/quiz/provider/quiz_timing_tracker.dart). No I/O; the
// current time (ms) is passed in.
//
// The whole-quiz clock starts when the server first handed out the questions
// (lined up with this device's clock through offsetMs); a question's clock
// starts when it is first shown. Both keep running while the page is hidden
// or closed, so neither can be refilled by a refresh. The quiz also closes at
// its end time (closingDeadline), whatever time limits it has.
export class QuizTimingTracker {
  #timings = new Map()
  #serverStartedAt = null
  #endsAt = null
  #offsetMs = 0
  #localStart = 0
  #overallLimit = null
  #perQuestionLimit = null

  // Starts tracking [questionIds]. Saved timings are kept for questions still
  // in the quiz; one that was on screen when the page closed is closed at
  // [savedAt], the last moment the page was known to be running.
  load({
    questionIds,
    localStart,
    saved = {},
    savedAt = null,
    serverStartedAt = null,
    endsAt = null,
    offsetMs = 0,
    overallLimit = null,
    perQuestionLimit = null,
  }) {
    this.#timings.clear()
    for (const id of questionIds) {
      const timing = saved[id]
      if (!timing) continue
      const since = timing.visibleSince
      this.#timings.set(id, since == null ? timing : timing.hidden(savedAt != null && savedAt > since ? savedAt : since))
    }
    this.#serverStartedAt = serverStartedAt
    this.#endsAt = endsAt
    this.#offsetMs = offsetMs
    this.#localStart = localStart
    this.#overallLimit = overallLimit
    this.#perQuestionLimit = perQuestionLimit
  }

  get timings() {
    return Object.fromEntries(this.#timings)
  }

  get serverStartedAt() {
    return this.#serverStartedAt
  }

  get offsetMs() {
    return this.#offsetMs
  }

  timingOf(id) {
    return this.#timings.get(id) ?? QuestionTiming.empty
  }

  // When the quiz started, on this device's clock.
  get quizStart() {
    return this.#serverStartedAt == null ? this.#localStart : this.#serverStartedAt - this.#offsetMs
  }

  get overallDeadline() {
    return this.#overallLimit == null ? null : this.quizStart + this.#overallLimit * 1000
  }

  // When the quiz itself closes (its end time), on this device's clock.
  get closingDeadline() {
    return this.#endsAt == null ? null : this.#endsAt - this.#offsetMs
  }

  // Null when questions have no time limit or [id] was never shown.
  questionDeadline(id) {
    const shown = this.timingOf(id).firstShownAt
    if (this.#perQuestionLimit == null || shown == null) return null
    return shown + this.#perQuestionLimit * 1000
  }

  // Whether [id] can still be answered at [now].
  isOpen(id, now) {
    if (this.timingOf(id).timedOut) return false
    return [this.questionDeadline(id), this.overallDeadline, this.closingDeadline].every(
      (deadline) => deadline == null || now < deadline,
    )
  }

  // Whole seconds since the quiz started.
  secondsSinceStart(now) {
    return Math.max(0, Math.trunc((now - this.quizStart) / 1000))
  }

  show(id, now) {
    this.#timings.set(id, this.timingOf(id).shown(now))
  }

  hide(id, now) {
    this.#timings.set(id, this.timingOf(id).hidden(now))
  }

  resume(id, now) {
    this.#timings.set(id, this.timingOf(id).resumed(now))
  }

  answered(id, now, { previous, choice }) {
    this.#timings.set(id, this.timingOf(id).answered(now, { previous, choice }))
  }

  // [id]'s countdown ran out: it took its full time.
  expire(id, now) {
    const deadline = this.questionDeadline(id)
    const limit = this.#perQuestionLimit
    this.#timings.set(
      id,
      this.timingOf(id).expiredAt(deadline != null && deadline < now ? deadline : now, limit == null ? null : limit * 1000),
    )
  }
}
