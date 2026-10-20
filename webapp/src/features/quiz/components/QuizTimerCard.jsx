import { AlarmClock } from 'lucide-react'
import { timerLabel } from '../stores/quizTimerStore'

// One countdown in a small glass box: alarm icon, label and the time left,
// turning to the warning colour and beating once a second in its last ten
// seconds.
export default function QuizTimerCard({ label, seconds }) {
  const warn = seconds <= 10
  return (
    <div className="flex items-center gap-2.5 rounded-2xl border border-glass-line bg-glass px-3 py-2 backdrop-blur-md sm:gap-3 sm:px-4 sm:py-2.5">
      <span aria-hidden="true" className={`grid size-8 shrink-0 place-items-center rounded-full sm:size-10 ${warn ? 'bg-coral-soft text-coral' : 'bg-rose-soft text-brand'}`}>
        <AlarmClock className="size-[18px] sm:size-[22px]" />
      </span>
      <div className="leading-none">
        <p className="whitespace-nowrap text-[11px] text-muted sm:text-[13px]">{label}</p>
        <p className={`mt-1 text-lg font-bold tabular-nums sm:text-2xl ${warn ? 'text-coral' : 'text-brand'}`}>
          <span className={warn ? 'qs-heartbeat' : ''}>{timerLabel(seconds)}</span>
        </p>
      </div>
    </div>
  )
}
