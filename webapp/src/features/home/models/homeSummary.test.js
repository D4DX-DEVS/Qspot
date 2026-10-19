import { describe, expect, it } from 'vitest'
import { whenLabel } from '../../../utils/formatDate'
import { featuredQuiz, quizFacts, quizStats } from './homeSummary'

const NOW = new Date(2026, 9, 19, 10, 0)
const quiz = (over) => ({
  id: 'q',
  title: 'Quiz',
  questionCount: 10,
  timerMode: 'none',
  overallTimeLimit: null,
  startDate: null,
  endDate: null,
  isLive: false,
  isUpcoming: false,
  isEnded: false,
  hasAttempted: false,
  myAttempt: null,
  ...over,
})
const taken = (id, percentage) => quiz({ id, isEnded: true, hasAttempted: true, myAttempt: { percentage } })

describe('featuredQuiz', () => {
  it('features the live quiz closing first and counts the others', () => {
    const later = quiz({ id: 'b', isLive: true, endDate: new Date(2026, 9, 25) })
    const sooner = quiz({ id: 'a', isLive: true, endDate: new Date(2026, 9, 19, 18, 10) })
    const hero = featuredQuiz({ quizList: [later, sooner] }, NOW)
    expect(hero).toMatchObject({ kind: 'live', action: 'Start Quiz', more: 1, meta: 'Ends today 6:10 pm' })
    expect(hero.quiz.id).toBe('a')
  })

  it('offers to carry on with a quiz started on this device', () => {
    const live = quiz({ id: 'a', isLive: true })
    const record = { quizId: 'a', answeredCount: 3, questionIds: Array(10).fill('x') }
    expect(featuredQuiz({ quizList: [live], inProgress: [record] }, NOW)).toMatchObject({
      eyebrow: 'CONTINUE YOUR QUIZ',
      action: 'Continue Quiz',
      detail: '3 of 10 answered',
    })
  })

  it('skips quizzes taken or already submitted, then shows the next to open', () => {
    const done = quiz({ id: 'a', isLive: true, hasAttempted: true, myAttempt: { percentage: 80 } })
    const sent = quiz({ id: 'b', isLive: true })
    const soon = quiz({ id: 'c', isUpcoming: true, startDate: new Date(2026, 9, 20, 9, 0) })
    const hero = featuredQuiz({ quizList: [done, sent, soon], waiting: [{ quizId: 'b' }] }, NOW)
    expect(hero).toMatchObject({ kind: 'upcoming', meta: 'Opens tomorrow 9:00 am' })
  })

  it('is caught up after taking everything, empty with no quizzes', () => {
    expect(featuredQuiz({ quizList: [taken('a', 50)] }, NOW).kind).toBe('caughtUp')
    expect(featuredQuiz({ quizList: [] }, NOW).kind).toBe('empty')
  })
})

describe('home numbers', () => {
  it('averages the server percentages of quizzes taken', () => {
    expect(quizStats([taken('a', 80), taken('b', 65), quiz({ id: 'c', isLive: true })])).toEqual({ taken: 2, average: 73 })
    expect(quizStats([])).toEqual({ taken: 0, average: null })
  })

  it('words quiz facts and dates', () => {
    expect(quizFacts(quiz({ timerMode: 'overall', overallTimeLimit: 600 }))).toBe('10 Questions · 10 min')
    expect(quizFacts(quiz({ questionCount: 1 }))).toBe('1 Question')
    expect(whenLabel(new Date(2026, 9, 26), NOW)).toBe('26 Oct')
  })
})
