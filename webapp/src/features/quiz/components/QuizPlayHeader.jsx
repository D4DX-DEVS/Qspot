import { ArrowLeft } from 'lucide-react'
import AnimatedProgressBar from '../../../components/common/AnimatedProgressBar'
import QuizTimerCards from './QuizTimerCards'

// Top of the question page: back, "Question 1 of 10", the progress bar with
// "1/10", and the countdowns on the right. Progress and timers show only
// once the questions are in ([total] > 0).
export default function QuizPlayHeader({ title, current, total, timer, onBack }) {
  const showing = total > 0
  return (
    <div className="mx-auto grid w-full max-w-[1040px] grid-cols-[minmax(0,1fr)_auto] items-center gap-x-4 gap-y-2 px-4 pb-3 pt-[calc(12px+env(safe-area-inset-top))] sm:gap-x-8 sm:pt-[calc(20px+env(safe-area-inset-top))]">
      <div className="min-w-0">
        <div className="flex items-center gap-3 sm:gap-4">
          <button
            type="button"
            aria-label="Back"
            onClick={onBack}
            className="group qs-press grid size-11 shrink-0 place-items-center rounded-full border border-glass-line bg-glass text-ink hover:border-brand/40 sm:size-12"
          >
            <ArrowLeft size={22} aria-hidden="true" className="transition-transform duration-200 motion-safe:group-hover:-translate-x-0.5" />
          </button>
          <h1 className="line-clamp-2 min-w-0 text-lg font-bold leading-tight text-ink sm:text-xl">{title}</h1>
        </div>
        {showing ? (
          <div className="mt-3 flex items-center gap-3 sm:mt-4">
            <div className="min-w-0 flex-1">
              <AnimatedProgressBar value={current / total} label={title} />
            </div>
            <span className="shrink-0 text-sm font-semibold tabular-nums text-muted" aria-hidden="true">
              {current}/{total}
            </span>
          </div>
        ) : null}
      </div>
      {showing && timer.hasCountdown ? <QuizTimerCards timer={timer} /> : null}
    </div>
  )
}
