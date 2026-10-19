import { ChangeNotifier } from '../../../lib/ChangeNotifier'
import { clock } from '../../../lib/clock'

// Which countdown ran out on a tick.
export const Expiry = Object.freeze({ none: 'none', overall: 'overall', closing: 'closing', question: 'question' })

// How long before the quiz closes the "Closes in" warning shows.
export const CLOSING_WARNING_SECONDS = 5 * 60

// "m:ss" label for a countdown value.
export const timerLabel = (seconds) => `${Math.trunc(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`

// Whole seconds left until [deadline] (ms), rounded up, never below zero.
export const secondsUntil = (deadline) => Math.max(0, Math.ceil((deadline - clock.now()) / 1000))

// Screen state for the question page: the countdowns in the header and whether
// a submission is in flight
// (mobile-app/lib/screens/quiz/provider/quiz_question_screen_provider.dart).
// Each countdown runs to a fixed deadline and every tick reads the clock, so
// time that passes while the tab is hidden or the page was closed still
// counts. The whole-quiz and per-question deadlines are independent.
export class QuizTimerStore extends ChangeNotifier {
  submitting = false
  timerStarted = false
  overallRemaining = null
  questionRemaining = null
  #closingRemaining = null
  #overallDeadline = null
  #questionDeadline = null
  #closingDeadline = null
  #overallReported = false
  #questionReported = false
  #closingReported = false

  // Seconds until the quiz closes, only in the last few minutes and only when
  // it comes before the quiz's own time limit.
  get closingWarning() {
    const closing = this.#closingRemaining
    if (closing == null || closing > CLOSING_WARNING_SECONDS) return null
    const overall = this.overallRemaining
    return overall != null && overall <= closing ? null : closing
  }

  get hasCountdown() {
    return this.overallRemaining != null || this.questionRemaining != null || this.closingWarning != null
  }

  setSubmitting(value) {
    this.submitting = value
    this.notifyListeners()
  }

  // Starts the countdowns that are set.
  startTimers({ overallDeadline = null, questionDeadline = null, closingDeadline = null }) {
    this.timerStarted = true
    this.#overallDeadline = overallDeadline
    this.#questionDeadline = questionDeadline
    this.#closingDeadline = closingDeadline
    this.#overallReported = false
    this.#questionReported = false
    this.#closingReported = false
    this.#refresh()
    this.notifyListeners()
  }

  // The current question changed: count down to its own deadline.
  setQuestionDeadline(deadline) {
    if (deadline === this.#questionDeadline) return
    this.#questionDeadline = deadline
    this.#questionReported = false
    this.#refresh()
    this.notifyListeners()
  }

  #refresh() {
    const overall = this.#overallDeadline == null ? null : secondsUntil(this.#overallDeadline)
    const question = this.#questionDeadline == null ? null : secondsUntil(this.#questionDeadline)
    const closing = this.#closingDeadline == null ? null : secondsUntil(this.#closingDeadline)
    const changed = overall !== this.overallRemaining || question !== this.questionRemaining || closing !== this.#closingRemaining
    this.overallRemaining = overall
    this.questionRemaining = question
    this.#closingRemaining = closing
    return changed
  }

  // Re-reads the clock and reports a countdown that just reached zero (the
  // whole-quiz ones win over the question's). Each is reported once.
  tick() {
    const changed = this.#refresh()
    let expired = Expiry.none
    if (this.overallRemaining === 0 && !this.#overallReported) {
      this.#overallReported = true
      expired = Expiry.overall
    }
    if (this.#closingRemaining === 0 && !this.#closingReported) {
      this.#closingReported = true
      if (expired === Expiry.none) expired = Expiry.closing
    }
    if (this.questionRemaining === 0 && !this.#questionReported) {
      this.#questionReported = true
      if (expired === Expiry.none) expired = Expiry.question
    }
    if (changed) this.notifyListeners()
    return expired
  }
}
