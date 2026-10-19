// A row of choice chips, one selected, scrolling sideways when they don't fit.
export default function FilterChipBar({ options, selected, onSelect, labelFor }) {
  return (
    <div className="flex gap-2 overflow-x-auto" role="tablist">
      {options.map((option) => {
        const active = option === selected
        return (
          <button
            key={option}
            type="button"
            role="tab"
            aria-selected={active}
            onClick={() => onSelect(option)}
            className={`qs-press h-8 shrink-0 rounded-lg border border-field-line px-4 text-xs font-semibold ${active ? 'bg-brand-soft text-brand' : 'bg-card text-muted'}`}
          >
            {labelFor(option)}
          </button>
        )
      })}
    </div>
  )
}
