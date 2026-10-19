import { ArrowLeft, ArrowRight, Check } from 'lucide-react'
import QuestionDots from './QuestionDots'

const round = 'qs-press grid size-12 shrink-0 place-items-center rounded-full shadow-[0_1px_3px_rgb(0_0_0/0.2)] disabled:opacity-40'

// Previous, question dots and Next/Submit. A per-question timer makes the
// quiz one-way: no Previous and no jumping between numbers.
export default function QuizBottomBar({ quiz, submitting, onPrevious, onNext, onJump }) {
  const free = !quiz.hasPerQuestionTimer
  const last = !quiz.hasNextQuestion
  return (
    <nav className="sticky bottom-0 z-10 border-t border-line bg-bg shadow-[0_-2px_10px_var(--qs-bar-shadow)]">
      <div className="mx-auto flex max-w-3xl items-center justify-between p-4 pb-[calc(16px+env(safe-area-inset-bottom))]">
        {free ? (
          <button type="button" aria-label="Previous" disabled={!quiz.hasPreviousQuestion} onClick={onPrevious} className={`${round} border border-line bg-card text-brand`}>
            <ArrowLeft size={24} aria-hidden="true" />
          </button>
        ) : null}
        <QuestionDots quiz={quiz} onJump={free ? onJump : null} />
        <button type="button" aria-label={last ? 'Submit' : 'Next'} disabled={submitting} onClick={onNext} className={`${round} bg-brand text-white`}>
          {last ? <Check size={24} aria-hidden="true" /> : <ArrowRight size={24} aria-hidden="true" />}
        </button>
      </div>
    </nav>
  )
}
