import { whenLabel } from '../../../utils/formatDate'

// Short facts about a quiz for its cards: how many questions, how long, and
// when it ends, opens or ended. Read only from the quiz list.

// "10 Questions"
export const questionsLabel = (quiz) => `${quiz.questionCount} Question${quiz.questionCount === 1 ? '' : 's'}`

// "5 min" when the whole quiz has a time limit, else null.
export function minutesLabel(quiz) {
  const timed = (quiz.timerMode === 'overall' || quiz.timerMode === 'both') && (quiz.overallTimeLimit ?? 0) > 0
  return timed ? `${Math.max(1, Math.round(quiz.overallTimeLimit / 60))} min` : null
}

// "Ends tomorrow 5:21 pm" / "Starts 26 Oct" / "Ended 12 Oct", or null.
export function scheduleLabel(quiz, now = new Date()) {
  if (quiz.isLive) return quiz.endDate ? `Ends ${whenLabel(quiz.endDate, now)}` : 'Open now'
  if (quiz.isUpcoming) return quiz.startDate ? `Starts ${whenLabel(quiz.startDate, now)}` : null
  return quiz.endDate ? `Ended ${whenLabel(quiz.endDate, now)}` : null
}
