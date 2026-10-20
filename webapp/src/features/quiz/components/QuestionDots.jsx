import { useEffect, useRef } from 'react'
import { Check } from 'lucide-react'

// Numbered dots for every question: current filled pink, answered ringed
// with a small tick, unanswered outlined. Each has a 44px+ tap area. In a
// one-way quiz (no [onJump]) they only show progress. The current dot
// scrolls into view when the question changes.
export default function QuestionDots({ quiz, onJump }) {
  const current = quiz.currentQuestionIndex
  const strip = useRef(null)

  useEffect(() => {
    const box = strip.current
    const dot = box?.children[current]
    if (!box || !dot) return
    // The strip is the offset parent, so offsetLeft is within it.
    const start = dot.offsetLeft
    const end = start + dot.offsetWidth
    if (start >= box.scrollLeft && end <= box.scrollLeft + box.clientWidth) return
    // Centre it, scrolling only the strip (never the page).
    box.scrollTo({ left: start + dot.offsetWidth / 2 - box.clientWidth / 2, behavior: 'smooth' })
  }, [current])

  return (
    <ul ref={strip} aria-label="Questions" className="relative flex min-w-0 items-center overflow-x-auto px-1 py-0.5 [scrollbar-width:none] sm:py-1">
      {quiz.sessionQuestions.map((q, index) => {
        const isCurrent = index === current
        const answered = quiz.selectedAnswer(q.id) != null
        const look = isCurrent
          ? 'qs-pop text-white shadow-[0_4px_12px_var(--qs-cta-shadow)]'
          : answered
            ? 'border-[1.5px] border-brand/80 bg-brand-soft text-ink'
            : 'border-[1.5px] border-field-line text-muted'
        const dot = (
          <span
            className={`relative grid size-9 place-items-center rounded-full text-sm font-semibold sm:size-10 ${look}`}
            style={isCurrent ? { backgroundImage: 'var(--qs-cta)' } : undefined}
          >
            {index + 1}
            {answered && !isCurrent ? (
              <span className="qs-pop absolute -right-1 -top-1 grid size-3.5 place-items-center rounded-full bg-brand text-on-brand" aria-hidden="true">
                <Check size={9} strokeWidth={3.5} />
              </span>
            ) : null}
          </span>
        )
        const label = `Question ${index + 1}${answered ? ', answered' : ', not answered'}`
        return (
          <li key={q.id} className="shrink-0">
            {onJump ? (
              <button
                type="button"
                aria-label={label}
                aria-current={isCurrent ? 'step' : undefined}
                onClick={() => onJump(index)}
                className="qs-press grid size-11 place-items-center rounded-full [--qs-press:0.88] sm:size-12"
              >
                {dot}
              </button>
            ) : (
              <span role="img" aria-label={label} aria-current={isCurrent ? 'step' : undefined} className="grid size-11 place-items-center sm:size-12">
                {dot}
              </span>
            )}
          </li>
        )
      })}
    </ul>
  )
}
