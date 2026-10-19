// Thin progress bar that glides to [value] (0..1).
export default function AnimatedProgressBar({ value, label }) {
  const pct = Math.round(Math.min(1, Math.max(0, value)) * 100)
  return (
    <div role="progressbar" aria-label={label} aria-valuenow={pct} aria-valuemin={0} aria-valuemax={100} className="h-1 w-full overflow-hidden rounded-full bg-brand-soft">
      <div className="h-full rounded-full bg-brand transition-[width] duration-700 ease-[cubic-bezier(0.215,0.61,0.355,1)] motion-reduce:transition-none" style={{ width: `${pct}%` }} />
    </div>
  )
}
