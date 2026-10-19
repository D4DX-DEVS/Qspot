import ToneChip from '../../../components/common/ToneChip'
import { timerLabel } from '../stores/quizTimerStore'

// Countdown pills, right-aligned above the question; each turns to the
// warning tone in its last ten seconds.
export default function QuizTimerChips({ timer }) {
  const chip = (label, seconds) => <ToneChip key={label} label={`${label} ${timerLabel(seconds)}`} tone={seconds <= 10 ? 'coral' : 'rose'} />
  return (
    <div className="flex flex-wrap justify-end gap-x-2 gap-y-1 px-4 pt-1" aria-live="off">
      {timer.overallRemaining != null ? chip('Time', timer.overallRemaining) : null}
      {timer.closingWarning != null ? chip('Closes in', timer.closingWarning) : null}
      {timer.questionRemaining != null ? chip('This question', timer.questionRemaining) : null}
    </div>
  )
}
