import { ArrowLeft } from 'lucide-react'

// Round outlined "Previous question" button of the quiz's bottom bar.
export default function QuizPrevButton({ disabled, onClick }) {
  return (
    <button
      type="button"
      aria-label="Previous"
      disabled={disabled}
      onClick={onClick}
      className="qs-press grid size-[52px] shrink-0 place-items-center rounded-full border-[1.5px] border-brand/80 text-brand disabled:opacity-40 sm:size-14"
    >
      <ArrowLeft size={24} aria-hidden="true" />
    </button>
  )
}
