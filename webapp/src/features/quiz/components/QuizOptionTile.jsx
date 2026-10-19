import { Check } from 'lucide-react'

// One answer choice: card with a round tick that fills brand when picked.
export default function QuizOptionTile({ label, selected, onPick }) {
  return (
    <button
      type="button"
      role="radio"
      aria-checked={selected}
      onClick={onPick}
      className={`qs-press flex w-full items-center gap-4 rounded-2xl p-4 text-left ${
        selected ? 'border-2 border-brand bg-brand text-white' : 'border border-line bg-card text-ink hover:border-brand/40'
      }`}
    >
      <span
        aria-hidden="true"
        className={`grid size-6 shrink-0 place-items-center rounded-full border ${selected ? 'qs-pop border-white bg-white/25' : 'border-line bg-brand-soft'}`}
      >
        {selected ? <Check size={15} className="text-white" /> : null}
      </span>
      <span className={`min-w-0 flex-1 text-base ${selected ? 'font-semibold' : ''}`}>{label}</span>
    </button>
  )
}
