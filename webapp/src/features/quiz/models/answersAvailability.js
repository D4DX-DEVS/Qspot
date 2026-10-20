import { clockTime, dayShortMonth, sameDay } from '../../../utils/formatDate'

// "5:05 pm today" or "5:05 pm on 21 Oct".
const when = (at, now) => `${clockTime(at)} ${sameDay(at, now) ? 'today' : `on ${dayShortMonth(at)}`}`

// The line shown in place of the correct answers while the server holds them
// back (mobile-app/lib/screens/quiz/model/answers_availability.dart). A null
// [availableAt] means they never show (practice with no end date).
export function answersHiddenMessage(availableAt, now = new Date()) {
  if (availableAt == null) {
    return "Correct answers aren't shown for this one, so it stays fair for everyone."
  }
  return `Correct answers show after ${when(availableAt, now)}, once everyone has finished.`
}

// Shown instead of the score after submitting: the score is held back with
// the answers until the quiz closes for everyone.
export function submittedMessage(availableAt, now = new Date()) {
  const later = availableAt == null ? 'once the quiz has closed.' : `after ${when(availableAt, now)}, once everyone has finished.`
  return `Your answers have been submitted. Your score will show ${later}`
}
