import QuizTimerCard from './QuizTimerCard'

// The running countdowns side by side: whole quiz, closing time, this question.
export default function QuizTimerCards({ timer }) {
  return (
    <div className="flex flex-wrap justify-end gap-2">
      {timer.overallRemaining != null ? <QuizTimerCard label="Time left" seconds={timer.overallRemaining} /> : null}
      {timer.closingWarning != null ? <QuizTimerCard label="Closes in" seconds={timer.closingWarning} /> : null}
      {timer.questionRemaining != null ? <QuizTimerCard label="This question" seconds={timer.questionRemaining} /> : null}
    </div>
  )
}
