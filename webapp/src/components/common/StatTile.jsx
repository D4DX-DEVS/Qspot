import { tone as toneOf } from '../../theme/tones'
import CountUpText from './CountUpText'
import SurfaceCard from './SurfaceCard'

// Small card with a coloured icon over a bold value and a short label.
export default function StatTile({ icon: Icon, tone, value, label }) {
  return (
    <SurfaceCard padding="px-2 py-3.5" className="h-full rounded-2xl">
      <div className="flex flex-col items-center text-center" aria-label={`${value} ${label}`}>
        <Icon size={24} className={toneOf(tone).text} aria-hidden="true" />
        <p className="mt-2 text-lg font-bold text-ink" aria-hidden="true">
          <CountUpText text={String(value)} />
        </p>
        <p className="mt-0.5 text-xs text-muted" aria-hidden="true">
          {label}
        </p>
      </div>
    </SurfaceCard>
  )
}
