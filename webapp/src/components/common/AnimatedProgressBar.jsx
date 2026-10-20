// Progress bar that glides to [value] (0..1), filled pink to coral, with a
// soft gleam running along the fill.
export default function AnimatedProgressBar({ value, label }) {
  const pct = Math.round(Math.min(1, Math.max(0, value)) * 100)
  return (
    <div role="progressbar" aria-label={label} aria-valuenow={pct} aria-valuemin={0} aria-valuemax={100} className="h-2 w-full overflow-hidden rounded-full bg-line">
      <div
        className="qs-gleam h-full rounded-full transition-[width] duration-700 ease-[cubic-bezier(0.215,0.61,0.355,1)] motion-reduce:transition-none"
        style={{ width: `${pct}%`, backgroundImage: 'var(--qs-cta)' }}
      />
    </div>
  )
}
