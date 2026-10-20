import { createElement } from 'react'
import { ChangeNotifier } from '../../../lib/ChangeNotifier'
import { ApiException } from '../../../services/apiClient'
import { dialogStore } from '../../../stores/dialogStore'
import { toastStore } from '../../../stores/toastStore'
import { authStore } from '../../auth/stores/authStore'
import QuizLeaveDialog from '../components/QuizLeaveDialog'
import QuizSubmitDialog from '../components/QuizSubmitDialog'
import QuizSubmitFailedDialog from '../components/QuizSubmitFailedDialog'
import QuizTooLateDialog from '../components/QuizTooLateDialog'
import { showSubmittedNotice } from '../actions/submittedNotice'
import { isDefiniteRejection, isTooLate } from '../services/quizSubmissionService'
import { quizStore } from './quizStore'
import { Expiry, QuizTimerStore } from './quizTimerStore'

// Runs the question page (the state half of quiz_question_screen.dart): the
// one-second ticker, hiding/showing the tab, reopening the quiz after a page
// refresh, and the submit flow. The page only draws what this exposes.
export class QuizPlayStore extends ChangeNotifier {
  timer = new QuizTimerStore()
  // Reopening the quiz from this device's copy after a refresh.
  resuming = false
  #quizId
  #navigate = () => {}
  #interval = null
  #pendingReset = null
  #warned = false

  constructor(quizId) {
    super()
    this.#quizId = quizId
  }

  // Called when the page appears. Returns the clean-up for when it goes.
  attach(navigate) {
    this.#navigate = navigate
    // A quick unmount/remount (React dev mode) must not end the quiz.
    clearTimeout(this.#pendingReset)
    const onVisibility = () => (document.hidden ? this.#onHidden() : this.#onVisible())
    const onPageHide = () => quizStore.pauseVisit()
    document.addEventListener('visibilitychange', onVisibility)
    window.addEventListener('pagehide', onPageHide)
    this.#ensureSession()
    return () => {
      document.removeEventListener('visibilitychange', onVisibility)
      window.removeEventListener('pagehide', onPageHide)
      this.#stopTicker()
      // Leaving mid-quiz: the question on screen stops counting time, and the
      // session ends (the answers stay saved on this device).
      quizStore.pauseVisit()
      this.#pendingReset = setTimeout(() => quizStore.resetSession(), 0)
    }
  }

  // The quiz is in memory when opened from the list; after a refresh it is
  // reopened from the saved copy, in the language it was started in.
  async #ensureSession() {
    if (quizStore.isQuizActive && quizStore.quizId === this.#quizId) {
      quizStore.resumeVisit()
      this.#startTimersIfConfigured()
      return
    }
    const saved = quizStore.savedProgress(this.#quizId)
    if (!saved || saved.isRefused) {
      this.#navigate('/quizzes', { replace: true })
      return
    }
    this.resuming = true
    this.notifyListeners()
    try {
      await quizStore.startQuiz(this.#quizId, saved.language)
      this.resuming = false
      this.notifyListeners()
      this.#startTimersIfConfigured()
    } catch (e) {
      this.resuming = false
      this.notifyListeners()
      toastStore.show(e instanceof ApiException ? e.message : 'Something went wrong. Please try again.', 'warning')
      this.#navigate('/quizzes', { replace: true })
    }
  }

  #startTimersIfConfigured() {
    if (!quizStore.isQuizActive) return
    if (!this.timer.timerStarted) {
      const overall = quizStore.overallDeadline
      const question = quizStore.questionDeadline
      const closing = quizStore.closingDeadline
      if (overall == null && question == null && closing == null) return
      this.timer.startTimers({ overallDeadline: overall, questionDeadline: question, closingDeadline: closing })
    }
    this.#interval ??= setInterval(() => this.#onTick(), 1000)
    // Reopened after a deadline passed: act on it now.
    this.#onTick()
  }

  #stopTicker() {
    clearInterval(this.#interval)
    this.#interval = null
  }

  #onTick() {
    // Paused while a submit is in flight, so it can't fire a second one.
    if (this.timer.submitting) return
    const expired = this.timer.tick()
    this.#warnBeforeTimeUp()
    switch (expired) {
      case Expiry.overall:
      case Expiry.closing:
        this.submit()
        break
      case Expiry.question:
        // Skipped as timed out (keeping an answer picked in time); the next
        // one starts its own clock, and after the last the quiz submits.
        if (quizStore.timeOutCurrentQuestion()) this.timer.setQuestionDeadline(quizStore.questionDeadline)
        else this.submit()
        break
      default:
        break
    }
  }

  // One heads-up, a minute before the quiz submits by itself (its time limit
  // or its closing time, whichever comes first).
  #warnBeforeTimeUp() {
    if (this.#warned) return
    const overall = this.timer.overallRemaining
    const closing = this.timer.closingWarning
    if (overall != null && overall > 0 && overall <= 60) {
      this.#warned = true
      toastStore.show('1 minute left. Your quiz will be submitted automatically when time is up.', 'warning')
    } else if (closing != null && closing > 0 && closing <= 60) {
      this.#warned = true
      toastStore.show('This quiz closes in 1 minute. Your answers will be submitted automatically then.', 'warning')
    }
  }

  // Leaving a timed quiz asks first: the answers are kept, but its clock keeps
  // running. Never asked while submitting or once the sign-in is gone.
  get shouldConfirmLeave() {
    return (
      quizStore.isQuizActive &&
      quizStore.quizId === this.#quizId &&
      !this.timer.submitting &&
      authStore.isAuthenticated &&
      (quizStore.hasOverallTimer || quizStore.hasPerQuestionTimer)
    )
  }

  // [blocker] is React Router's held navigation: carried on or cancelled.
  async confirmLeave(blocker) {
    const leave = await dialogStore.show((close) => createElement(QuizLeaveDialog, { onClose: close }), { dismissValue: false })
    if (leave) blocker.proceed()
    else blocker.reset()
  }

  // In the background the question stops counting time on screen, but every
  // countdown keeps running; coming back re-reads them straight away.
  #onHidden() {
    quizStore.pauseVisit()
  }

  #onVisible() {
    quizStore.resumeVisit()
    if (this.timer.timerStarted) {
      this.timer.setQuestionDeadline(quizStore.questionDeadline)
      this.#onTick()
    }
  }

  previous() {
    quizStore.previousQuestion()
  }

  jump(index) {
    quizStore.goToQuestion(index)
  }

  // Next, or on the last question "Submit Quiz?".
  async next() {
    if (this.timer.submitting) return
    if (quizStore.hasNextQuestion) {
      quizStore.nextQuestion()
      this.timer.setQuestionDeadline(quizStore.questionDeadline)
      return
    }
    const confirmed = await dialogStore.show((close) =>
      createElement(QuizSubmitDialog, { answered: quizStore.answeredCount, total: quizStore.totalQuestions, onClose: close }),
    )
    if (confirmed) await this.submit()
  }

  // The timer and the dialog can both submit; only the first goes through.
  async submit() {
    if (this.timer.submitting) return
    this.timer.setSubmitting(true)
    // A timed-out submit can fire while "Submit Quiz?" is open.
    dialogStore.closeAll()
    const quizId = quizStore.quizId
    try {
      const attempt = await quizStore.submitQuiz()
      if (!attempt.answersRevealed) {
        // The score stays hidden until the quiz closes for everyone: say the
        // answers are in, then back to the quiz list.
        await showSubmittedNotice(attempt.answersAvailableAt)
        this.#navigate('/quizzes', { replace: true })
        return
      }
      // Only after a real server confirmation; stays "submitting" while the
      // page leaves, so the timer can't fire another submit.
      this.#navigate(`/quizzes/${attempt.quizId || quizId}/result`, { replace: true, state: { attempt } })
    } catch (e) {
      if (!isDefiniteRejection(e)) {
        await this.#offerRetry()
        return
      }
      if (isTooLate(e)) {
        await dialogStore.show((close) => createElement(QuizTooLateDialog, { endsAt: quizStore.endsAt, onClose: close }), {
          dismissible: false,
        })
        if (quizId) quizStore.dismissRefused(quizId)
        this.#navigate('/quizzes', { replace: true })
        return
      }
      // Refused for good (switched off, changed, removed): back to the list,
      // where a notice says why.
      toastStore.show(e.message, 'danger')
      this.#navigate('/quizzes', { replace: true })
    }
  }

  // No connection or a busy server: the answers are saved here, so the
  // student tries again now or leaves them to be sent later. Stays
  // "submitting" meanwhile, so the timer cannot submit behind the dialog.
  async #offerRetry() {
    const retry = await dialogStore.show((close) => createElement(QuizSubmitFailedDialog, { onClose: close }), {
      dismissible: false,
    })
    if (retry) {
      this.timer.setSubmitting(false)
      await this.submit()
    } else {
      this.#navigate('/quizzes', { replace: true })
    }
  }
}
