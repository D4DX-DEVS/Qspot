import { useEffect, useRef } from 'react'
import { Check } from 'lucide-react'

// Numbered dots for every question: current filled brand, answered ringed
// with a small tick, unanswered outlined. Each has a 44px tap area. In a
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
    <ul ref={strip} aria-label="Questions" className="relative flex min-w-0 flex-1 items-center overflow-x-auto px-2 py-1 [scrollbar-width:none]">
      {quiz.sessionQuestions.map((q, index) => {
        const isCurrent = index === current
        const answered = quiz.selectedAnswer(q.id) != null
        const look = isCurrent
          ? 'bg-brand text-on-brand'
          : answered
            ? 'bg-brand-soft text-brand ring-2 ring-brand/70'
            : 'border border-field-line bg-card text-muted'
        const dot = (
          <span className={`relative grid size-8 place-items-center rounded-full text-xs font-bold ${look}`}>
            {index + 1}
            {answered && !isCurrent ? (
              <span className="absolute -right-1 -top-1 grid size-3.5 place-items-center rounded-full bg-brand text-on-brand" aria-hidden="true">
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
                className="qs-press grid size-11 place-items-center rounded-full [--qs-press:0.88]"
              >
                {dot}
              </button>
            ) : (
              <span role="img" aria-label={label} aria-current={isCurrent ? 'step' : undefined} className="grid size-11 place-items-center">
                {dot}
              </span>
            )}
          </li>
        )
      })}
    </ul>
  )
}
