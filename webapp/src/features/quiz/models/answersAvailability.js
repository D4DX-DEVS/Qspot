import { clockTime, dayShortMonth, sameDay } from '../../../utils/formatDate'

// The line shown in place of the correct answers while the server holds them
// back (mobile-app/lib/screens/quiz/model/answers_availability.dart). A null
// [availableAt] means they never show (practice with no end date).
export function answersHiddenMessage(availableAt, now = new Date()) {
  if (availableAt == null) {
    return "Correct answers aren't shown for this one, so it stays fair for everyone."
  }
  const day = sameDay(availableAt, now) ? 'today' : `on ${dayShortMonth(availableAt)}`
  return `Correct answers show after ${clockTime(availableAt)} ${day}, once everyone has finished.`
}
