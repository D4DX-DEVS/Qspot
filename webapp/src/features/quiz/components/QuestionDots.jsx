import { useEffect, useRef } from 'react'

// Numbered dots for every question: current filled brand, answered tinted.
// Tapping jumps there unless the quiz is one-way. The current dot scrolls
// into view when the question changes.
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
    <div ref={strip} className="relative flex min-w-0 flex-1 items-center overflow-x-auto px-4 [scrollbar-width:none]" role="list" aria-label="Questions">
      {quiz.sessionQuestions.map((q, index) => {
        const isCurrent = index === current
        const answered = quiz.selectedAnswer(q.id) != null
        const colors = isCurrent ? 'bg-brand text-white' : answered ? 'bg-brand-soft text-brand' : 'bg-line text-muted'
        return (
          <button
            key={q.id}
            type="button"
            role="listitem"
            disabled={!onJump}
            aria-current={isCurrent ? 'step' : undefined}
            aria-label={`Question ${index + 1}${answered ? ', answered' : ''}`}
            onClick={() => onJump?.(index)}
            className={`qs-press mx-1 grid size-8 shrink-0 place-items-center rounded-full text-xs font-bold [--qs-press:0.88] ${colors}`}
          >
            {index + 1}
          </button>
        )
      })}
    </div>
  )
}
