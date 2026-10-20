import { ChevronRight } from 'lucide-react'
import { tone as toneOf } from '../../theme/tones'
import CountUpText from './CountUpText'
import GlassCard from './GlassCard'

// Card with an icon in a tinted circle, a bold value and a short label;
// stacked on phones, in a row with an arrow on wider screens. Becomes a
// button when [onClick] is set; hovered, its icon tilts up and the arrow
// nudges forward.
export default function StatTile({ icon: Icon, tone, value, label, onClick }) {
  const t = toneOf(tone)
  return (
    <GlassCard onClick={onClick} label={`${value} ${label}`} padding="px-2 py-4 sm:px-5 sm:py-5 lg:px-6" className="h-full">
      <div className="flex flex-col items-center gap-2 text-center sm:flex-row sm:gap-4 sm:text-left lg:gap-5">
        <span
          aria-hidden="true"
          className={`grid size-11 shrink-0 place-items-center rounded-full transition-transform duration-300 motion-safe:group-hover:-rotate-6 motion-safe:group-hover:scale-110 sm:size-14 lg:size-16 ${t.soft} ${t.text}`}
        >
          <Icon className="size-6 sm:size-7 lg:size-8" />
        </span>
        <div className="min-w-0 flex-1">
          <p className="text-xl font-bold leading-none text-ink sm:text-[26px] lg:text-[28px]">
            <CountUpText text={String(value)} />
          </p>
          <p className="mt-1 text-xs text-muted sm:mt-1.5 sm:text-[15px]">{label}</p>
        </div>
        {onClick ? (
          <span aria-hidden="true" className="hidden size-9 shrink-0 place-items-center rounded-full bg-soft-fill text-ink transition-transform duration-200 motion-safe:group-hover:translate-x-1 sm:grid">
            <ChevronRight size={18} />
          </span>
        ) : null}
      </div>
    </GlassCard>
  )
}
