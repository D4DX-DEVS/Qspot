import { useEffect, useRef } from 'react'
import { ArrowRight, Check } from 'lucide-react'
import PillButton from '../../../components/common/PillButton'
import QuestionDots from './QuestionDots'
import QuizPrevButton from './QuizPrevButton'

// Previous, question dots and Next Question / Submit Quiz: one row on wider
// screens; on phones the dots get their own row above Previous and a wide
// Next button. A per-question timer makes the quiz one-way: no Previous and
// no jumping between numbers. While shown it lifts snack bars above itself,
// so they never cover Next/Submit.
export default function QuizBottomBar({ quiz, submitting, onPrevious, onNext, onJump }) {
  const bar = useRef(null)
  const free = !quiz.hasPerQuestionTimer
  const last = !quiz.hasNextQuestion
  const previous = free ? <QuizPrevButton disabled={!quiz.hasPreviousQuestion} onClick={onPrevious} /> : null

  useEffect(() => {
    const node = bar.current
    if (!node) return undefined
    const root = document.documentElement
    const lift = () => root.style.setProperty('--qs-toast-offset', `${node.offsetHeight}px`)
    lift()
    const observer = new ResizeObserver(lift)
    observer.observe(node)
    return () => {
      observer.disconnect()
      root.style.removeProperty('--qs-toast-offset')
    }
  }, [])

  return (
    <nav ref={bar} aria-label="Question navigation" className="sticky bottom-0 z-10 border-t border-glass-line bg-bar backdrop-blur-md">
      <div className="mx-auto max-w-7xl px-3 pb-[calc(12px+env(safe-area-inset-bottom))] pt-2 sm:flex sm:items-center sm:gap-4 sm:px-6 sm:py-4 lg:px-10">
        <div className="flex min-w-0 items-center justify-center sm:flex-1 sm:gap-3">
          <div className="hidden sm:block">{previous}</div>
          <QuestionDots quiz={quiz} onJump={free ? onJump : null} />
        </div>
        <div className="mt-1.5 flex items-center gap-3 sm:mt-0">
          <div className="sm:hidden">{previous}</div>
          <PillButton
            label={last ? 'Submit Quiz' : 'Next Question'}
            icon={last ? Check : null}
            trailing={last ? null : ArrowRight}
            size="lg"
            disabled={submitting}
            onClick={onNext}
            className="flex-1 sm:min-w-[200px] sm:flex-none"
          />
        </div>
      </div>
    </nav>
  )
}
