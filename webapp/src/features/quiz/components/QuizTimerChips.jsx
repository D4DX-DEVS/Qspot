import { Timer } from 'lucide-react'
import { tone as toneOf } from '../../../theme/tones'
import { timerLabel } from '../stores/quizTimerStore'

// Countdown pills under the progress bar, kept on screen with it; each turns
// to the warning tone in its last ten seconds.
export default function QuizTimerChips({ timer }) {
  const chip = (label, seconds) => {
    const t = toneOf(seconds <= 10 ? 'coral' : 'rose')
    return (
      <span key={label} className={`inline-flex items-center gap-1.5 whitespace-nowrap rounded-full px-3 py-1.5 text-[13px] font-bold tabular-nums ${t.soft} ${t.text}`}>
        <Timer size={15} aria-hidden="true" />
        {label} {timerLabel(seconds)}
      </span>
    )
  }
  return (
    <div className="flex flex-wrap justify-end gap-x-2 gap-y-1.5 px-4 pb-2">
      {timer.overallRemaining != null ? chip('Time left', timer.overallRemaining) : null}
      {timer.closingWarning != null ? chip('Closes in', timer.closingWarning) : null}
      {timer.questionRemaining != null ? chip('This question', timer.questionRemaining) : null}
    </div>
  )
}
