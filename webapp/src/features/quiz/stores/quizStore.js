import { ChangeNotifier } from '../../../lib/ChangeNotifier'
import { clock } from '../../../lib/clock'
import { ApiClient, ApiException } from '../../../services/apiClient'
import { renewIfNeeded } from '../../../services/sessionRenewal'
import { Storage } from '../../../services/storage'
import { jsonInt } from '../../../utils/jsonParsing'
import { quizListItemFromJson, quizQuestionFromJson } from '../models/quizModels'
import { QuizProgressRecord } from '../models/quizProgressRecord'
import { QuizTimingTracker } from '../models/quizTimingTracker'
import { QuizOfflineStore } from '../services/quizOfflineStore'
import {
  discardAbandoned,
  flushPending,
  isConnectionTrouble,
  sealClosedQuizzes,
  sendSubmission,
} from '../services/quizSubmissionService'

// The quiz list and the quiz being taken: a port of
// mobile-app/lib/screens/quiz/provider/quiz_provider.dart.
//
// All grading is on the server; this never works out a score. Once opened, a
// quiz works offline: the questions come in one request and the answers are
// written to this device on every tap (QuizOfflineStore). They leave the
// device only after the server confirms the attempt.

// Shown when a submitted quiz, still waiting to be sent, is opened again.
export const SUBMITTED_WAITING_MESSAGE =
  "Your answers are submitted and waiting to be sent. They'll go as soon as there's a connection."

const parseIso = (value) => {
  const ms = Date.parse(value ?? '')
  return Number.isNaN(ms) ? null : ms
}

// Server time minus device time, reading the server's clock as halfway
// through the request; null when the server sent no time.
const clockOffset = (serverNow, sent, got) => {
  const server = parseIso(serverNow)
  return server == null ? null : server - (sent + Math.trunc((got - sent) / 2))
}

const currentUserId = () => Storage.getString('userId') || 'anon'

class QuizStore extends ChangeNotifier {
  // ---- Quiz list ----
  listState = 'idle' // 'idle' | 'loading' | 'loaded' | 'error'
  listError = ''
  quizList = []

  get isListLoading() {
    return this.listState === 'loading'
  }

  get hasListError() {
    return this.listState === 'error'
  }

  // GET /api/user-quizzes. Empty is normal (no live quiz right now).
  async fetchQuizList() {
    this.listState = 'loading'
    this.listError = ''
    this.notifyListeners()
    // Answers that could not be sent earlier go out alongside the list
    // request, so a result shows up as soon as the connection is back.
    const flushing = this.flushPendingSubmissions()
    try {
      const data = await ApiClient.get('/api/user-quizzes')
      this.quizList = (Array.isArray(data) ? data : []).map(quizListItemFromJson)
      this.listState = 'loaded'
    } catch (e) {
      this.listState = 'error'
      this.listError = e instanceof ApiException ? e.message : 'Failed to load quizzes'
    }
    this.notifyListeners()
    // A waiting submission was just accepted: reload so its score shows.
    if (await flushing) await this.fetchQuizList()
  }

  // ---- Active quiz session ----
  sessionState = 'idle'
  sessionError = ''
  quizId = null
  quizTitle = ''
  overallTimeLimit = null
  perQuestionTimeLimit = null
  timerMode = 'none'
  sessionQuestions = []
  currentQuestionIndex = 0
  // Locked when the quiz starts; never changes mid-quiz.
  sessionLanguage = 'en'
  // Opened from the device copy because the server could not be reached.
  openedFromDevice = false
  // The quiz's end time as the server set it (ms), for messages.
  endsAt = null
  lastAttempt = null

  #answers = new Map()
  #quizStartTime = null
  // Who the device copy belongs to; null means nothing is saved.
  #userId = null
  #submitPending = false
  #frozenDuration = null
  #tracker = new QuizTimingTracker()
  // The page is hidden: a question reached meanwhile is not shown yet, so its
  // clock waits for the student to come back.
  #paused = false

  get isSessionLoading() {
    return this.sessionState === 'loading'
  }

  get totalQuestions() {
    return this.sessionQuestions.length
  }

  get isQuizActive() {
    return this.sessionState === 'loaded' && this.sessionQuestions.length > 0
  }

  // Whether the whole quiz has a time limit.
  get hasOverallTimer() {
    return (this.timerMode === 'overall' || this.timerMode === 'both') && (this.overallTimeLimit ?? 0) > 0
  }

  // Whether each question has its own limit. Such a quiz only moves forward.
  get hasPerQuestionTimer() {
    return (this.timerMode === 'per-question' || this.timerMode === 'both') && (this.perQuestionTimeLimit ?? 0) > 0
  }

  get currentQuestion() {
    return this.sessionQuestions[this.currentQuestionIndex] ?? null
  }

  get hasNextQuestion() {
    return this.currentQuestionIndex < this.sessionQuestions.length - 1
  }

  get hasPreviousQuestion() {
    return this.currentQuestionIndex > 0
  }

  selectedAnswer(questionId) {
    return this.#answers.get(questionId) ?? null
  }

  get answeredCount() {
    return [...this.#answers.values()].filter((v) => v != null).length
  }

  // When the whole quiz's time runs out (device clock, ms), counted from when
  // the server first handed out the questions, so a refresh never refills it.
  get overallDeadline() {
    return this.#tracker.overallDeadline
  }

  // When the quiz closes at its end time (device clock, ms).
  get closingDeadline() {
    return this.#tracker.closingDeadline
  }

  // When the current question's own time runs out, or null.
  get questionDeadline() {
    const question = this.currentQuestion
    return question == null ? null : this.#tracker.questionDeadline(question.id)
  }

  timingOf(questionId) {
    return this.#tracker.timingOf(questionId)
  }

  // Whether [quizId] was submitted here and is waiting to be sent.
  isWaitingToSend(quizId) {
    return this.pendingSubmissions.some((r) => r.quizId === quizId)
  }

  // The saved copy of [quizId] for this student, if any (used to reopen a
  // quiz after a page refresh, in the language it was started in).
  savedProgress(quizId) {
    return QuizOfflineStore.loadProgress(currentUserId(), quizId)
  }

  // GET /api/user-quizzes/:id/questions. The server returns the same pinned
  // question set on repeat calls. Throws ApiException: 409 already attempted,
  // 403 not live. The questions are saved as soon as they arrive; when the
  // server cannot be reached and a saved copy exists, the quiz opens from it
  // with the earlier answers.
  async startQuiz(quizId, language) {
    this.sessionState = 'loading'
    this.sessionError = ''
    this.quizId = quizId
    this.#userId = null
    this.openedFromDevice = false
    if (language) this.sessionLanguage = language
    this.notifyListeners()

    // A sign-in about to run out is renewed now, not mid-quiz.
    renewIfNeeded()
    const userId = currentUserId()
    const saved = QuizOfflineStore.loadProgress(userId, quizId)
    if (saved?.isRetryable) {
      // Submit was pressed: final, only waiting to be sent, not reopened.
      this.sessionState = 'error'
      this.sessionError = SUBMITTED_WAITING_MESSAGE
      this.notifyListeners()
      throw new ApiException(0, this.sessionError)
    }
    let data
    let fromDevice = false
    let offsetMs = null
    try {
      const sentAt = clock.now()
      data = await ApiClient.get(`/api/user-quizzes/${quizId}/questions`, {
        // Someone resuming gives up on a dead connection sooner.
        timeout: saved == null ? undefined : 6000,
      })
      offsetMs = clockOffset(data?.serverNow, sentAt, clock.now())
      QuizOfflineStore.saveSession(userId, quizId, data)
    } catch (e) {
      const cached = isConnectionTrouble(e) ? QuizOfflineStore.loadSession(userId, quizId) : null
      if (cached == null) {
        this.sessionState = 'error'
        // The server already holds this attempt, so a half-finished copy
        // here has nothing left to send.
        if (e instanceof ApiException && e.status === 409) QuizOfflineStore.clear(userId, quizId)
        this.sessionError =
          e instanceof ApiException ? e.message : "You're offline. Connect to the internet to start this quiz."
        this.notifyListeners()
        throw e instanceof ApiException ? e : new ApiException(0, this.sessionError)
      }
      data = cached
      fromDevice = true
    }
    this.#userId = userId
    this.openedFromDevice = fromDevice
    this.#applySessionData(data, saved, offsetMs)
    this.notifyListeners()
  }

  // Fills the session from [data]; a saved [resume] record brings back the
  // answers, position and start time.
  #applySessionData(data, resume, offsetMs) {
    this.quizTitle = typeof data.title === 'string' ? data.title : ''
    this.overallTimeLimit = jsonInt(data.overallTimeLimit)
    this.perQuestionTimeLimit = jsonInt(data.perQuestionTimeLimit)
    this.timerMode = typeof data.timerMode === 'string' ? data.timerMode : 'none'
    this.sessionQuestions = (Array.isArray(data.questions) ? data.questions : []).map(quizQuestionFromJson)

    this.#answers = new Map(this.sessionQuestions.map((q) => [q.id, resume?.answers[q.id] ?? null]))
    const last = Math.max(0, this.sessionQuestions.length - 1)
    this.currentQuestionIndex = Math.min(Math.max(resume?.currentIndex ?? 0, 0), last)
    const now = clock.now()
    this.#quizStartTime = resume?.startedAt ?? now
    this.endsAt = parseIso(data.endDate)
    this.#submitPending = resume?.submitPending ?? false
    this.#frozenDuration = resume?.totalDuration ?? null
    this.#tracker = new QuizTimingTracker()
    this.#tracker.load({
      questionIds: this.sessionQuestions.map((q) => q.id),
      localStart: this.#quizStartTime,
      saved: resume?.timings ?? {},
      savedAt: resume?.savedAt ?? null,
      serverStartedAt: parseIso(data.startedAt),
      endsAt: this.endsAt,
      offsetMs: offsetMs ?? resume?.clockOffsetMs ?? 0,
      overallLimit: this.hasOverallTimer ? this.overallTimeLimit : null,
      perQuestionLimit: this.hasPerQuestionTimer ? this.perQuestionTimeLimit : null,
    })
    const current = this.currentQuestion
    if (current) this.#tracker.show(current.id, now)
    this.lastAttempt = null
    this.sessionState = 'loaded'
    this.#persistProgress()
  }

  // The quiz as it stands, in the form kept on the device.
  #snapshot() {
    return new QuizProgressRecord({
      quizId: this.quizId,
      title: this.quizTitle,
      questionIds: this.sessionQuestions.map((q) => q.id),
      answers: Object.fromEntries(this.#answers),
      language: this.sessionLanguage,
      startedAt: this.#quizStartTime ?? clock.now(),
      currentIndex: this.currentQuestionIndex,
      submitPending: this.#submitPending,
      totalDuration: this.#frozenDuration,
      timings: this.#tracker.timings,
      serverStartedAt: this.#tracker.serverStartedAt,
      endsAt: this.endsAt,
      clockOffsetMs: this.#tracker.offsetMs,
      savedAt: clock.now(),
    })
  }

  // Writes the answers and position to the device after every change.
  #persistProgress() {
    if (this.#userId == null || this.quizId == null || this.sessionQuestions.length === 0) return
    QuizOfflineStore.saveProgress(this.#userId, this.#snapshot())
  }

  // Test seam: an active session from raw question JSON, without a request.
  seedSessionForTest(questions, { quizId = 'test-quiz', timerMode = 'none', overallTimeLimit = null, perQuestionTimeLimit = null, endsAt = null } = {}) {
    this.quizId = quizId
    this.#applySessionData(
      {
        title: 'Test Quiz',
        questions,
        timerMode,
        overallTimeLimit,
        perQuestionTimeLimit,
        endDate: endsAt == null ? null : new Date(endsAt).toISOString(),
      },
      null,
      null,
    )
    this.notifyListeners()
  }

  // Picks an option for the current question; ignored once its time is up.
  selectAnswer(answerIndex) {
    const question = this.currentQuestion
    if (!question) return
    const now = clock.now()
    if (!this.#tracker.isOpen(question.id, now)) return
    this.#tracker.answered(question.id, now, { previous: this.#answers.get(question.id) ?? null, choice: answerIndex })
    this.#answers.set(question.id, answerIndex)
    this.#persistProgress()
    this.notifyListeners()
  }

  nextQuestion() {
    if (this.hasNextQuestion) this.#moveTo(this.currentQuestionIndex + 1)
  }

  previousQuestion() {
    if (this.hasPreviousQuestion) this.#moveTo(this.currentQuestionIndex - 1)
  }

  goToQuestion(index) {
    if (index >= 0 && index < this.sessionQuestions.length) this.#moveTo(index)
  }

  #moveTo(index) {
    const now = clock.now()
    const from = this.currentQuestion
    if (from) this.#tracker.hide(from.id, now)
    this.currentQuestionIndex = index
    if (!this.#paused) this.#tracker.show(this.sessionQuestions[index].id, now)
    this.#persistProgress()
    this.notifyListeners()
  }

  // The current question's time ran out: marked timed out (keeping an answer
  // picked in time) and the next question is shown. False on the last
  // question, where the quiz should submit.
  timeOutCurrentQuestion() {
    const question = this.currentQuestion
    if (!question) return false
    this.#tracker.expire(question.id, clock.now())
    if (this.hasNextQuestion) {
      this.#moveTo(this.currentQuestionIndex + 1)
      return true
    }
    this.#persistProgress()
    this.notifyListeners()
    return false
  }

  // The page was hidden or the quiz screen closed: the question on screen
  // stops counting time on screen (its countdown keeps running).
  pauseVisit() {
    this.#paused = true
    const question = this.currentQuestion
    if (!question) return
    this.#tracker.hide(question.id, clock.now())
    this.#persistProgress()
  }

  // The page is in front again. A question the quiz moved to meanwhile is
  // shown now, starting its clock.
  resumeVisit() {
    this.#paused = false
    const question = this.currentQuestion
    if (!question) return
    const now = clock.now()
    if (this.#tracker.timingOf(question.id).firstShownAt == null) this.#tracker.show(question.id, now)
    else this.#tracker.resume(question.id, now)
    this.#persistProgress()
    this.notifyListeners()
  }

  // POST /api/quizzes/attempt. Returns the graded attempt on a 201 or a 409
  // that carries it; any other error propagates. The final answers are saved
  // before anything is sent and removed only once the server confirms, so a
  // failed send loses nothing.
  async submitQuiz() {
    if (this.quizId == null || this.sessionQuestions.length === 0) throw new Error('No active quiz session to submit')
    const now = clock.now()
    const current = this.currentQuestion
    if (current) this.#tracker.hide(current.id, now)
    this.#frozenDuration ??= this.#tracker.secondsSinceStart(now)
    this.#submitPending = true
    const record = this.#snapshot()
    const userId = this.#userId
    if (userId != null) QuizOfflineStore.saveProgress(userId, record)

    const attempt = await sendSubmission(userId, record)
    // The server has it and the copy is gone; nothing may write it back.
    this.#userId = null
    this.lastAttempt = attempt
    this.notifyListeners()
    return attempt
  }

  // ---- Submissions waiting on the device ----
  pendingSubmissions = []
  refusedSubmissions = []
  inProgressQuizzes = []
  isFlushing = false

  // The student has seen why [quizId]'s answers were refused: the copy goes.
  dismissRefused(quizId) {
    if (quizId === this.quizId) this.#userId = null
    const userId = currentUserId()
    QuizOfflineStore.clear(userId, quizId)
    this.refusedSubmissions = QuizOfflineStore.refused(userId)
    this.notifyListeners()
  }

  // How many quizzes have answers here that the server does not have yet.
  unsentQuizCount() {
    return QuizOfflineStore.unsent(currentUserId()).length
  }

  // Deletes every saved quiz of the signed-in student, on logout.
  deleteSavedQuizzes() {
    this.#userId = null
    QuizOfflineStore.clearAll(currentUserId())
  }

  // Sends every waiting submission; true when any was accepted. Never throws.
  async flushPendingSubmissions() {
    if (this.isFlushing) return false
    this.isFlushing = true
    this.notifyListeners()
    let sent = false
    try {
      const userId = currentUserId()
      // The quiz open on screen submits by itself; leave it alone.
      const open = this.#userId != null ? this.quizId : null
      discardAbandoned(userId, clock.now(), open)
      sealClosedQuizzes(userId, clock.now(), open)
      sent = await flushPending(userId, open)
      this.pendingSubmissions = QuizOfflineStore.pending(userId)
      this.refusedSubmissions = QuizOfflineStore.refused(userId)
      this.inProgressQuizzes = QuizOfflineStore.inProgress(userId, clock.now())
    } catch (e) {
      console.warn('Could not send waiting quiz answers:', e)
    } finally {
      this.isFlushing = false
      this.notifyListeners()
    }
    return sent
  }

  // Ends the active session (leaving the quiz screen).
  resetSession() {
    this.quizId = null
    this.quizTitle = ''
    this.overallTimeLimit = null
    this.perQuestionTimeLimit = null
    this.timerMode = 'none'
    this.sessionQuestions = []
    this.currentQuestionIndex = 0
    this.#answers = new Map()
    this.#quizStartTime = null
    this.#userId = null
    this.#submitPending = false
    this.#frozenDuration = null
    this.openedFromDevice = false
    this.#paused = false
    this.endsAt = null
    this.#tracker = new QuizTimingTracker()
    this.lastAttempt = null
    this.sessionState = 'idle'
    this.sessionError = ''
    this.notifyListeners()
  }

  // Full reset on sign-out, so the next account never sees this one's list.
  // Answers saved on the device stay for the same student's next sign-in.
  clear() {
    this.resetSession()
    this.quizList = []
    this.listState = 'idle'
    this.listError = ''
    this.pendingSubmissions = []
    this.refusedSubmissions = []
    this.inProgressQuizzes = []
    this.notifyListeners()
  }
}

export { QuizStore }
export const quizStore = new QuizStore()
