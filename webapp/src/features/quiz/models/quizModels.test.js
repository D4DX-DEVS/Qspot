import { describe, expect, it } from 'vitest'
import { QuestionTiming } from './questionTiming'
import { QuizProgressRecord } from './quizProgressRecord'
import { QuizTimingTracker } from './quizTimingTracker'
import { optionsFor, questionText, quizAttemptFromJson } from './quizModels'
import { refusalMessage } from './quizRefusal'

const T0 = Date.parse('2026-10-19T10:00:00Z')
const sec = (s) => s * 1000

const record = (over = {}) =>
  new QuizProgressRecord({
    quizId: 'q1',
    title: 'Quran Quiz',
    questionIds: ['a', 'b'],
    answers: { a: 1, b: null },
    language: 'en',
    startedAt: T0,
    ...over,
  })

describe('QuestionTiming', () => {
  it('counts only time on screen, across visits', () => {
    let t = QuestionTiming.empty.shown(T0)
    t = t.hidden(T0 + sec(5))
    t = t.shown(T0 + sec(20)).hidden(T0 + sec(23))
    expect(t.spentMs).toBe(sec(8))
    expect(t.firstShownAt).toBe(T0)
  })

  it('records the time of the final answer, ignoring a repeat of the same pick', () => {
    let t = QuestionTiming.empty.shown(T0)
    t = t.answered(T0 + sec(3), { previous: null, choice: 2 })
    t = t.answered(T0 + sec(9), { previous: 2, choice: 2 })
    expect(t.timeTakenMs).toBe(sec(3))
    t = t.answered(T0 + sec(11), { previous: 2, choice: 0 })
    expect(t.timeTakenMs).toBe(sec(11))
  })

  it('takes the full limit when its countdown runs out', () => {
    const t = QuestionTiming.empty.shown(T0).expiredAt(T0 + sec(30), sec(30))
    expect(t.timedOut).toBe(true)
    expect(t.toSubmission()).toEqual({ duration: 30 })
  })

  it('survives a save and load', () => {
    const t = QuestionTiming.empty.shown(T0).answered(T0 + 1234, { previous: null, choice: 1 })
    expect(QuestionTiming.fromJSON(JSON.parse(JSON.stringify(t)))).toEqual(t)
  })
})

describe('QuizTimingTracker', () => {
  const tracker = (over = {}) => {
    const t = new QuizTimingTracker()
    t.load({ questionIds: ['a', 'b'], localStart: T0, ...over })
    return t
  }

  it('runs the whole-quiz clock from the server start, lined up with this clock', () => {
    // Server is 2 s ahead; it started the quiz 60 s before our local start.
    const t = tracker({ serverStartedAt: T0 - sec(58), offsetMs: sec(2), overallLimit: 600 })
    expect(t.quizStart).toBe(T0 - sec(60))
    expect(t.overallDeadline).toBe(T0 + sec(540))
  })

  it('closes every question at the overall, question and closing deadlines', () => {
    const t = tracker({ overallLimit: 100, perQuestionLimit: 10, endsAt: T0 + sec(50) })
    t.show('a', T0)
    expect(t.isOpen('a', T0 + sec(9))).toBe(true)
    expect(t.isOpen('a', T0 + sec(10))).toBe(false)
    t.show('b', T0 + sec(45))
    expect(t.isOpen('b', T0 + sec(49))).toBe(true)
    expect(t.isOpen('b', T0 + sec(50))).toBe(false)
  })

  it('closes a question left on screen at the last save time when reloaded', () => {
    const saved = { a: QuestionTiming.empty.shown(T0) }
    const t = tracker({ saved, savedAt: T0 + sec(7) })
    expect(t.timingOf('a').visibleSince).toBe(null)
    expect(t.timingOf('a').spentMs).toBe(sec(7))
  })

  it('expires a question at its deadline even when noticed late', () => {
    const t = tracker({ perQuestionLimit: 20 })
    t.show('a', T0)
    t.expire('a', T0 + sec(90))
    expect(t.timingOf('a').spentMs).toBe(sec(20))
    expect(t.timingOf('a').timedOut).toBe(true)
  })
})

describe('QuizProgressRecord', () => {
  it('builds the submission body the server expects', () => {
    const r = record({ language: 'ml', timings: { a: new QuestionTiming({ spentMs: 4260 }) } })
    expect(r.toSubmissionBody(42)).toEqual({
      quizId: 'q1',
      language: 'Malayalam',
      answers: [
        { questionId: 'a', attemptedAnswer: 1, duration: 4.3 },
        { questionId: 'b', attemptedAnswer: null, duration: 0 },
      ],
      totalDuration: 42,
    })
  })

  it('knows when a quiz closed without being submitted, using the server clock', () => {
    const r = record({ endsAt: T0 + sec(100), clockOffsetMs: sec(10) })
    expect(r.closedUnsubmitted(T0 + sec(89))).toBe(false)
    expect(r.closedUnsubmitted(T0 + sec(91))).toBe(true)
    expect(r.copyWith({ submitPending: true }).closedUnsubmitted(T0 + sec(91))).toBe(false)
  })

  it('treats an unanswered copy as abandoned once the quiz is over', () => {
    const empty = record({ answers: { a: null, b: null }, endsAt: T0 + sec(10) })
    expect(empty.abandoned(T0 + sec(5))).toBe(false)
    expect(empty.abandoned(T0 + sec(11))).toBe(true)
    expect(record({ endsAt: T0 + sec(10) }).abandoned(T0 + sec(11))).toBe(false)
  })

  it('seals a closed quiz as submitted at the last moment it was seen', () => {
    const r = record({
      endsAt: T0 + sec(300),
      savedAt: T0 + sec(120),
      timings: { a: QuestionTiming.empty.shown(T0 + sec(100)) },
    })
    const sealed = r.sealedAfterClose()
    expect(sealed.submitPending).toBe(true)
    expect(sealed.totalDuration).toBe(120)
    expect(sealed.timings.a.spentMs).toBe(sec(20))
  })

  it('round-trips through JSON and ignores damaged entries', () => {
    const r = record({ rejectedStatus: 403, rejectedCode: 'QUIZ_CLOSED', endsAt: T0 + 5 })
    const back = QuizProgressRecord.tryFromJSON(JSON.parse(JSON.stringify(r)))
    expect(back).toEqual(r)
    expect(back.arrivedTooLate).toBe(true)
    expect(QuizProgressRecord.tryFromJSON({ quizId: 'x' })).toBe(null)
    expect(QuizProgressRecord.tryFromJSON('junk')).toBe(null)
  })

  it('words a refusal for the student', () => {
    expect(refusalMessage(record({ rejectedStatus: 403, rejectedCode: 'QUIZ_CLOSED' }))).toContain('after the quiz closed')
    expect(refusalMessage(record({ rejectedStatus: 400, rejectedCode: 'QUESTIONS_CHANGED' }))).toContain('were changed')
  })
})

describe('quiz API shapes', () => {
  const q = { questionEn: 'Q', questionMl: 'ചോ', optionsEn: ['a', 'b'], optionsMl: ['അ'] }

  it('falls back to English when Malayalam is missing or short', () => {
    expect(questionText(q, 'ml')).toBe('ചോ')
    expect(optionsFor(q, 'ml')).toEqual(['a', 'b'])
    expect(questionText({ ...q, questionMl: '' }, 'ml')).toBe('Q')
  })

  it('reads answersRevealed, defaulting for older servers', () => {
    expect(quizAttemptFromJson({ results: [] }).answersRevealed).toBe(false)
    expect(quizAttemptFromJson({ results: [{ questionId: 'a', isCorrect: true }] }).answersRevealed).toBe(true)
    expect(quizAttemptFromJson({ results: [], answersRevealed: true, percentage: '87.5' }).percentage).toBe(87.5)
  })
})
