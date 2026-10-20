// One answer choice: a rounded row with a radio circle; picked, a soft pink
// wash fills in from the left, the rim turns pink and the radio fills.
export default function QuizOptionTile({ label, selected, onPick }) {
  return (
    <button
      type="button"
      role="radio"
      aria-checked={selected}
      onClick={onPick}
      className={`qs-press flex min-h-16 w-full items-center gap-4 rounded-[18px] border px-4 py-3.5 text-left text-ink [--qs-press:0.985] sm:min-h-[72px] sm:gap-5 sm:px-6 ${
        selected ? 'qs-wash border-brand shadow-[0_0_0_1px_var(--qs-brand),0_6px_18px_var(--qs-cta-shadow)]' : 'border-glass-line bg-field hover:border-brand/50'
      }`}
      style={selected ? { backgroundImage: 'var(--qs-option-picked)' } : undefined}
    >
      <span
        aria-hidden="true"
        className={`grid size-7 shrink-0 place-items-center rounded-full border-2 sm:size-8 ${selected ? 'qs-pop border-brand bg-brand shadow-[0_0_12px_var(--qs-cta-shadow)]' : 'border-field-line'}`}
      >
        {selected ? <span className="qs-dot-in size-3 rounded-full bg-white sm:size-3.5" /> : null}
      </span>
      <span className={`min-w-0 flex-1 text-base sm:text-lg ${selected ? 'font-semibold' : ''}`}>{label}</span>
    </button>
  )
}
