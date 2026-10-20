import { ChartNoAxesColumnIncreasing } from 'lucide-react'
import { tone as toneOf } from '../../../theme/tones'

const TONE = { easy: 'mint', medium: 'amber', hard: 'coral' }

// EASY / MEDIUM / HARD pill with a little bar chart, above the question.
export default function DifficultyChip({ difficulty }) {
  const t = toneOf(TONE[difficulty.toLowerCase()] ?? 'slate')
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-bold uppercase tracking-[0.04em] sm:text-[13px] ${t.soft} ${t.text}`}
      style={{ borderColor: `color-mix(in srgb, ${t.color} 50%, transparent)` }}
    >
      <ChartNoAxesColumnIncreasing size={15} strokeWidth={3} aria-hidden="true" />
      {difficulty}
    </span>
  )
}
