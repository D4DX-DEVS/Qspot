// Hairline with a word in the middle, e.g. "OR" between two ways in.
export default function OrDivider({ label = 'OR' }) {
  return (
    <div className="flex items-center gap-4" role="separator" aria-label={label}>
      <span className="h-px flex-1 bg-field-line/60" aria-hidden="true" />
      <span className="text-[13px] font-medium text-muted" aria-hidden="true">
        {label}
      </span>
      <span className="h-px flex-1 bg-field-line/60" aria-hidden="true" />
    </div>
  )
}
