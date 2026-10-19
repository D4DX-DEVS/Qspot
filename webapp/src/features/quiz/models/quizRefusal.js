import { REMOVED_CODE, SWITCHED_OFF_CODE, TOO_LATE_CODE } from './quizProgressRecord'

// Why a student's answers were refused, in plain words for the Quiz page
// (mobile-app/lib/screens/quiz/model/quiz_refusal.dart).
export function refusalMessage(record) {
  const quiz = record.title === '' ? 'your quiz' : `"${record.title}"`
  const code = record.rejectedCode
  if (code === TOO_LATE_CODE) {
    return `Your answers for ${quiz} reached us after the quiz closed, so they could not be marked. Please speak to your teacher.`
  }
  if (code === SWITCHED_OFF_CODE) {
    return `Your answers for ${quiz} couldn't be submitted because the quiz was switched off. Please speak to your teacher.`
  }
  if (code === REMOVED_CODE) {
    return `Your answers for ${quiz} couldn't be submitted because the quiz was removed. Please speak to your teacher.`
  }
  if (record.canRetake) {
    return `Your answers for ${quiz} couldn't be submitted because the quiz's questions were changed after you started.`
  }
  return `Your answers for ${quiz} couldn't be submitted. Please speak to your teacher.`
}
