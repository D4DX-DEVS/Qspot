import { whenLabel } from '../../../utils/formatDate'

// What the home screen shows above the quiz list: the one quiz to feature in
// the hero card and the student's numbers. Read only from the quiz list the
// server sent (scores are the server's); nothing is graded here.

const byEndThenTitle = (a, b) => (a.endDate?.getTime() ?? Infinity) - (b.endDate?.getTime() ?? Infinity) || a.title.localeCompare(b.title)
const byStart = (a, b) => (a.startDate?.getTime() ?? Infinity) - (b.startDate?.getTime() ?? Infinity)

// "10 Questions · 10 min" (minutes only when the whole quiz has a limit).
export function quizFacts(quiz) {
  const count = `${quiz.questionCount} Question${quiz.questionCount === 1 ? '' : 's'}`
  const timed = (quiz.timerMode === 'overall' || quiz.timerMode === 'both') && (quiz.overallTimeLimit ?? 0) > 0
  return timed ? `${count} · ${Math.max(1, Math.round(quiz.overallTimeLimit / 60))} min` : count
}

// The hero card: a live quiz still to take (the one closing first; carried
// on from this device when it was started here), else the next one to open,
// else "all caught up" or "nothing yet".
export function featuredQuiz({ quizList, inProgress = [], waiting = [] }, now = new Date()) {
  const startedHere = new Map(inProgress.map((r) => [r.quizId, r]))
  const sent = new Set(waiting.map((r) => r.quizId))
  const toTake = quizList.filter((q) => q.isLive && !q.hasAttempted && !sent.has(q.id)).sort(byEndThenTitle)
  if (toTake.length) {
    const quiz = toTake[0]
    const record = startedHere.get(quiz.id) ?? null
    return {
      kind: 'live',
      quiz,
      record,
      eyebrow: record ? 'CONTINUE YOUR QUIZ' : 'LIVE NOW',
      meta: quiz.endDate ? `Ends ${whenLabel(quiz.endDate, now)}` : null,
      detail: record ? `${record.answeredCount} of ${record.questionIds.length} answered` : quizFacts(quiz),
      more: toTake.length - 1,
      action: record ? 'Continue Quiz' : 'Start Quiz',
    }
  }
  const next = quizList.filter((q) => q.isUpcoming).sort(byStart)[0]
  if (next) {
    return {
      kind: 'upcoming',
      quiz: next,
      eyebrow: 'COMING UP',
      meta: next.startDate ? `Opens ${whenLabel(next.startDate, now)}` : null,
      detail: quizFacts(next),
      action: 'See Details',
    }
  }
  return quizList.some((q) => q.hasAttempted) ? { kind: 'caughtUp' } : { kind: 'empty' }
}

// Quizzes taken and the average of their server-given percentages. A score
// counts once its quiz has closed for everyone; until then it is hidden.
export function quizStats(quizList) {
  const taken = quizList.filter((q) => q.hasAttempted)
  const scored = taken.filter((q) => q.myAttempt.answersRevealed)
  const average = scored.length ? Math.round(scored.reduce((sum, q) => sum + q.myAttempt.percentage, 0) / scored.length) : null
  return { taken: taken.length, average }
}
