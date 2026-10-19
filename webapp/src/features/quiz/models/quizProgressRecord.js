import { QuestionTiming } from './questionTiming'

// A student's quiz as kept on this device while they take it
// (mobile-app/lib/screens/quiz/model/quiz_progress_record.dart): which
// questions they got, what they answered, where they are, when they began,
// and whether Submit was pressed. Everything needed to send the answers later
// lives here, so a submission survives a refresh or a dropped connection. The
// record is only deleted once the server has confirmed the attempt.
//
// Times are milliseconds since the epoch (saved as ISO text).

// The server's reasons for refusing answers (Qspot-API routes/quizzes.js).
export const TOO_LATE_CODE = 'QUIZ_CLOSED'
export const SWITCHED_OFF_CODE = 'QUIZ_DISABLED'
export const REMOVED_CODE = 'QUIZ_NOT_FOUND'
export const QUESTIONS_CHANGED_CODES = new Set(['QUESTIONS_CHANGED', 'NO_SESSION'])

// How long a copy saved without an end time is kept when unanswered.
const UNANSWERED_KEEP_MS = 30 * 24 * 60 * 60 * 1000

export class QuizProgressRecord {
  constructor({
    quizId,
    title,
    questionIds,
    answers,
    language,
    startedAt,
    currentIndex = 0,
    submitPending = false,
    totalDuration = null,
    rejectedStatus = null,
    rejectedCode = null,
    timings = {},
    serverStartedAt = null,
    endsAt = null,
    clockOffsetMs = 0,
    savedAt = null,
  }) {
    this.quizId = quizId
    this.title = title
    // The questions in the order they were served.
    this.questionIds = questionIds
    // questionId -> chosen option index, or null while unanswered.
    this.answers = answers
    // 'en' or 'ml', as chosen in the language dialog.
    this.language = language
    this.startedAt = startedAt
    this.currentIndex = currentIndex
    // True once Submit was pressed: final, waiting for the server.
    this.submitPending = submitPending
    // Seconds taken, frozen when Submit was pressed.
    this.totalDuration = totalDuration
    // HTTP status of a definite refusal (e.g. 403 quiz closed); the answers
    // are kept but no longer retried on their own.
    this.rejectedStatus = rejectedStatus
    this.rejectedCode = rejectedCode
    // questionId -> QuestionTiming.
    this.timings = timings
    // When the server first handed out the questions; the quiz clock runs
    // from here, so it survives a refresh or a changed device clock.
    this.serverStartedAt = serverStartedAt
    // When the quiz closes (server clock).
    this.endsAt = endsAt
    // Server time minus device time, measured when last opened online.
    this.clockOffsetMs = clockOffsetMs
    // Last write: the page was certainly running then.
    this.savedAt = savedAt
    Object.freeze(this)
  }

  get arrivedTooLate() {
    return this.rejectedCode === TOO_LATE_CODE
  }

  // The server refused these answers for good.
  get isRefused() {
    return this.rejectedStatus != null
  }

  // Refused because the questions changed: the quiz can be taken again.
  get canRetake() {
    return QUESTIONS_CHANGED_CODES.has(this.rejectedCode)
  }

  // Waiting to be sent, and not refused for good.
  get isRetryable() {
    return this.submitPending && this.rejectedStatus == null
  }

  get answeredCount() {
    return Object.values(this.answers).filter((v) => v != null).length
  }

  // Started, not submitted, and the quiz closed at [now] (device clock): the
  // page was not open on the quiz when it ended, so nothing was sent.
  closedUnsubmitted(now) {
    return !this.submitPending && this.rejectedStatus == null && this.endsAt != null && now + this.clockOffsetMs > this.endsAt
  }

  // Opened but nothing answered, and the quiz is over (or, with no end time,
  // the copy is older than 30 days): nothing to send or continue.
  abandoned(now) {
    return (
      !this.submitPending &&
      this.rejectedStatus == null &&
      this.answeredCount === 0 &&
      (this.endsAt == null ? now - this.startedAt > UNANSWERED_KEEP_MS : this.closedUnsubmitted(now))
    )
  }

  // The answers as last saved become final, as if Submit had been pressed
  // the last moment the page was known to be running.
  sealedAfterClose() {
    const lastSeen = this.savedAt ?? this.startedAt
    const start = this.serverStartedAt == null ? this.startedAt : this.serverStartedAt - this.clockOffsetMs
    const timings = {}
    for (const [id, timing] of Object.entries(this.timings)) timings[id] = timing.hidden(lastSeen)
    return new QuizProgressRecord({
      ...this.#fields(),
      submitPending: true,
      totalDuration: Math.max(0, Math.trunc((lastSeen - start) / 1000)),
      timings,
      rejectedStatus: null,
      rejectedCode: null,
    })
  }

  // The body of POST /api/quizzes/attempt.
  toSubmissionBody(duration) {
    return {
      quizId: this.quizId,
      // The server only recognises the literal 'Malayalam'.
      language: this.language === 'ml' ? 'Malayalam' : 'English',
      answers: this.questionIds.map((id) => ({
        questionId: id,
        attemptedAnswer: this.answers[id] ?? null,
        ...(this.timings[id] ?? QuestionTiming.empty).toSubmission(),
      })),
      totalDuration: duration,
    }
  }

  copyWith(changes = {}) {
    const { clearRejected = false, ...rest } = changes
    return new QuizProgressRecord({
      ...this.#fields(),
      ...rest,
      ...(clearRejected ? { rejectedStatus: null, rejectedCode: null } : {}),
    })
  }

  #fields() {
    return {
      quizId: this.quizId,
      title: this.title,
      questionIds: this.questionIds,
      answers: this.answers,
      language: this.language,
      startedAt: this.startedAt,
      currentIndex: this.currentIndex,
      submitPending: this.submitPending,
      totalDuration: this.totalDuration,
      rejectedStatus: this.rejectedStatus,
      rejectedCode: this.rejectedCode,
      timings: this.timings,
      serverStartedAt: this.serverStartedAt,
      endsAt: this.endsAt,
      clockOffsetMs: this.clockOffsetMs,
      savedAt: this.savedAt,
    }
  }

  toJSON() {
    const iso = (ms) => (ms == null ? null : new Date(ms).toISOString())
    const timings = {}
    for (const [id, timing] of Object.entries(this.timings)) timings[id] = timing.toJSON()
    return {
      quizId: this.quizId,
      title: this.title,
      questionIds: this.questionIds,
      answers: this.answers,
      language: this.language,
      startedAt: iso(this.startedAt),
      currentIndex: this.currentIndex,
      submitPending: this.submitPending,
      totalDuration: this.totalDuration,
      rejectedStatus: this.rejectedStatus,
      rejectedCode: this.rejectedCode,
      timings,
      serverStartedAt: iso(this.serverStartedAt),
      endsAt: iso(this.endsAt),
      clockOffsetMs: this.clockOffsetMs,
      savedAt: iso(this.savedAt),
    }
  }

  // Null when [json] is not a usable record (damaged or from another
  // version), so a bad entry is ignored instead of breaking the quiz.
  static tryFromJSON(json) {
    if (!json || typeof json !== 'object') return null
    const started = Date.parse(json.startedAt ?? '')
    if (typeof json.quizId !== 'string' || !Array.isArray(json.questionIds) || Number.isNaN(started)) return null
    const date = (key) => {
      const ms = Date.parse(json[key] ?? '')
      return Number.isNaN(ms) ? null : ms
    }
    const int = (v) => (Number.isInteger(v) ? v : null)
    const answers = {}
    if (json.answers && typeof json.answers === 'object') {
      for (const [id, value] of Object.entries(json.answers)) answers[id] = int(value)
    }
    const timings = {}
    if (json.timings && typeof json.timings === 'object') {
      for (const [id, value] of Object.entries(json.timings)) timings[id] = QuestionTiming.fromJSON(value)
    }
    return new QuizProgressRecord({
      quizId: json.quizId,
      title: typeof json.title === 'string' ? json.title : '',
      questionIds: json.questionIds.map(String),
      answers,
      language: json.language === 'ml' ? 'ml' : 'en',
      startedAt: started,
      currentIndex: int(json.currentIndex) ?? 0,
      submitPending: json.submitPending === true,
      totalDuration: int(json.totalDuration),
      rejectedStatus: int(json.rejectedStatus),
      rejectedCode: typeof json.rejectedCode === 'string' ? json.rejectedCode : null,
      timings,
      serverStartedAt: date('serverStartedAt'),
      endsAt: date('endsAt'),
      clockOffsetMs: int(json.clockOffsetMs) ?? 0,
      savedAt: date('savedAt'),
    })
  }
}
