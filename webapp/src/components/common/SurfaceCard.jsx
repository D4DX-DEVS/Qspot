// Plain rounded card: card colour, hairline border and a soft shadow.
// Becomes a button when [onClick] is set.
export default function SurfaceCard({ onClick, className = '', padding = 'p-4', borderClass = 'border-line', label, children }) {
  const base = `block w-full rounded-[18px] border bg-card text-left shadow-[0_4px_14px_var(--qs-card-shadow)] ${borderClass} ${padding} ${className}`
  if (!onClick) return <div className={base}>{children}</div>
  return (
    <button type="button" onClick={onClick} aria-label={label} className={`qs-press [--qs-press:0.97] hover:brightness-[0.985] ${base}`}>
      {children}
    </button>
  )
}
