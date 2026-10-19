// Thin bar filled to a percentage: green from 70%, amber from 50%, else coral.
export default function ScoreBar({ percentage }) {
  const pct = Math.min(100, Math.max(0, percentage))
  const fill = pct >= 70 ? 'bg-mint' : pct >= 50 ? 'bg-amber' : 'bg-coral'
  return (
    <div aria-hidden="true" className="h-1.5 w-full overflow-hidden rounded-full bg-line">
      <div className={`h-full rounded-full ${fill}`} style={{ width: `${Math.max(pct, 3)}%` }} />
    </div>
  )
}
