import { beforeEach, describe, expect, it } from 'vitest'
import { clock } from '../../../lib/clock'
import { Storage } from '../../../services/storage'
import { fakeServer, offline } from '../../../test/fakeServer'
import { QuizOfflineStore } from '../services/quizOfflineStore'
import { retryDelays } from '../services/quizSubmissionService'
import { QuizStore } from './quizStore'
import { Expiry, QuizTimerStore } from './quizTimerStore'

const T0 = Date.parse('2026-10-19T10:00:00Z')
let now = T0
clock.now = () => now

const questions = [
  { _id: 'a', question_en: 'One?', options_en: ['x', 'y'] },
  { _id: 'b', question_en: 'Two?', options_en: ['x', 'y'] },
]
const session = (over = {}) => ({
  title: 'Quran Quiz',
  questions,
  timerMode: 'overall',
  overallTimeLimit: 600,
  startedAt: new Date(T0).toISOString(),
  // The server's clock at the moment it answers.
  serverNow: new Date(now).toISOString(),
  endDate: new Date(T0 + 3600_000).toISOString(),
  ...over,
})
const attempt = { attemptId: 't1', quizId: 'q1', score: 1, totalQuestions: 2, percentage: 50, results: [] }

beforeEach(() => {
  now = T0
  retryDelays.values = [0, 0]
  Storage.setString('userId', 'u1')
  Storage.setString('auth_token', 'not-a-jwt')
})

describe('QuizStore', () => {
  it('saves answers on every tap and resumes them after a refresh', async () => {
    fakeServer(() => ({ status: 200, body: session() }))
    const store = new QuizStore()
    await store.startQuiz('q1', 'ml')
    store.selectAnswer(1)
    store.nextQuestion()

    const fresh = new QuizStore()
    const saved = fresh.savedProgress('q1')
    expect(saved.answers).toEqual({ a: 1, b: null })
    expect(saved.language).toBe('ml')
    await fresh.startQuiz('q1', saved.language)
    expect(fresh.currentQuestionIndex).toBe(1)
    expect(fresh.selectedAnswer('a')).toBe(1)
    expect(fresh.sessionLanguage).toBe('ml')
  })

  it('opens from the saved copy when the connection drops', async () => {
    fakeServer(() => ({ status: 200, body: session() }))
    const store = new QuizStore()
    await store.startQuiz('q1', 'en')
    store.selectAnswer(0)

    fakeServer(offline)
    const again = new QuizStore()
    await again.startQuiz('q1', 'en')
    expect(again.openedFromDevice).toBe(true)
    expect(again.selectedAnswer('a')).toBe(0)
  })

  it('refuses to start offline with nothing saved', async () => {
    fakeServer(offline)
    const store = new QuizStore()
    await expect(store.startQuiz('q1', 'en')).rejects.toThrow("You're offline")
  })

  it('never refills the whole-quiz clock on reopening', async () => {
    fakeServer(() => ({ status: 200, body: session() }))
    const store = new QuizStore()
    await store.startQuiz('q1', 'en')
    now = T0 + 120_000
    const again = new QuizStore()
    await again.startQuiz('q1', 'en')
    expect(again.overallDeadline).toBe(T0 + 600_000)
  })

  it('removes the device copy only after the server confirms', async () => {
    const calls = fakeServer((method) =>
      method === 'GET' ? { status: 200, body: session() } : { status: 503, body: { message: 'busy' } },
    )
    const store = new QuizStore()
    await store.startQuiz('q1', 'en')
    store.selectAnswer(1)
    now = T0 + 42_000
    await expect(store.submitQuiz()).rejects.toThrow()
    expect(calls.filter((c) => c.method === 'POST')).toHaveLength(3) // first try + 2 re-sends
    const waiting = QuizOfflineStore.pending('u1')
    expect(waiting).toHaveLength(1)
    expect(waiting[0].totalDuration).toBe(42)

    fakeServer((method, path) =>
      path === '/api/user-quizzes' ? { status: 200, body: [] } : { status: 201, body: { attempt } },
    )
    const later = new QuizStore()
    await later.fetchQuizList()
    expect(QuizOfflineStore.pending('u1')).toHaveLength(0)
    expect(later.pendingSubmissions).toHaveLength(0)
  })

  it('takes a 409 that carries the saved attempt as success', async () => {
    fakeServer((method) =>
      method === 'GET' ? { status: 200, body: session() } : { status: 409, body: { message: 'Already attempted', attempt } },
    )
    const store = new QuizStore()
    await store.startQuiz('q1', 'en')
    const result = await store.submitQuiz()
    expect(result.attemptId).toBe('t1')
    expect(QuizOfflineStore.loadProgress('u1', 'q1')).toBe(null)
  })

  it('keeps refused answers, marked, and stops retrying them', async () => {
    fakeServer((method) =>
      method === 'GET' ? { status: 200, body: session() } : { status: 403, body: { message: 'closed', code: 'QUIZ_CLOSED' } },
    )
    const store = new QuizStore()
    await store.startQuiz('q1', 'en')
    await expect(store.submitQuiz()).rejects.toThrow()
    const saved = QuizOfflineStore.loadProgress('u1', 'q1')
    expect(saved.rejectedCode).toBe('QUIZ_CLOSED')
    expect(QuizOfflineStore.pending('u1')).toHaveLength(0)
    expect(QuizOfflineStore.refused('u1')).toHaveLength(1)
  })

  it('does not reopen a quiz that is submitted and waiting', async () => {
    fakeServer((method) => (method === 'GET' ? { status: 200, body: session() } : offline()))
    const store = new QuizStore()
    await store.startQuiz('q1', 'en')
    await expect(store.submitQuiz()).rejects.toThrow()
    await expect(new QuizStore().startQuiz('q1', 'en')).rejects.toThrow('waiting to be sent')
  })

  it('ignores answers after a per-question timer runs out and moves on', async () => {
    fakeServer(() => ({ status: 200, body: session({ timerMode: 'per-question', perQuestionTimeLimit: 10 }) }))
    const store = new QuizStore()
    await store.startQuiz('q1', 'en')
    now = T0 + 11_000
    store.selectAnswer(0)
    expect(store.selectedAnswer('a')).toBe(null)
    expect(store.timeOutCurrentQuestion()).toBe(true)
    expect(store.currentQuestionIndex).toBe(1)
    expect(store.questionDeadline).toBe(T0 + 21_000)
    now = T0 + 22_000
    expect(store.timeOutCurrentQuestion()).toBe(false)
  })

  it('seals and sends a quiz that closed while the page was away', async () => {
    fakeServer((method, path) => {
      if (path.endsWith('/questions')) return { status: 200, body: session({ endDate: new Date(T0 + 60_000).toISOString() }) }
      if (path === '/api/user-quizzes') return { status: 200, body: [] }
      return { status: 201, body: { attempt } }
    })
    const store = new QuizStore()
    await store.startQuiz('q1', 'en')
    store.selectAnswer(1)
    store.resetSession()
    now = T0 + 120_000
    const calls = fakeServer((method, path) =>
      path === '/api/user-quizzes' ? { status: 200, body: [] } : { status: 201, body: { attempt } },
    )
    await new QuizStore().fetchQuizList()
    const post = calls.find((c) => c.method === 'POST')
    expect(post.body.answers[0]).toMatchObject({ questionId: 'a', attemptedAnswer: 1 })
    expect(QuizOfflineStore.loadProgress('u1', 'q1')).toBe(null)
  })
})

describe('QuizTimerStore', () => {
  it('reports each countdown once, the whole quiz winning over the question', () => {
    const timer = new QuizTimerStore()
    timer.startTimers({ overallDeadline: T0 + 5_000, questionDeadline: T0 + 3_000 })
    expect(timer.tick()).toBe(Expiry.none)
    expect(timer.overallRemaining).toBe(5)
    now = T0 + 3_000
    expect(timer.tick()).toBe(Expiry.question)
    expect(timer.tick()).toBe(Expiry.none)
    now = T0 + 5_000
    expect(timer.tick()).toBe(Expiry.overall)
    // Both at zero together: only the whole quiz is reported (it submits).
    const both = new QuizTimerStore()
    both.startTimers({ overallDeadline: T0 + 5_000, questionDeadline: T0 + 5_000 })
    expect(both.tick()).toBe(Expiry.overall)
    expect(both.tick()).toBe(Expiry.none)
  })

  it('warns about closing only in the last five minutes and before the time limit', () => {
    const timer = new QuizTimerStore()
    timer.startTimers({ closingDeadline: T0 + 400_000 })
    expect(timer.closingWarning).toBe(null)
    now = T0 + 200_000
    timer.tick()
    expect(timer.closingWarning).toBe(200)
    timer.startTimers({ closingDeadline: T0 + 400_000, overallDeadline: T0 + 250_000 })
    expect(timer.closingWarning).toBe(null)
  })
})
