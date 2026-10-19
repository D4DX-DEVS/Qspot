import { tone as toneOf } from '../../../theme/tones'

const TONE = { easy: 'mint', medium: 'amber', hard: 'coral' }

// EASY / MEDIUM / HARD pill above the question.
export default function DifficultyChip({ difficulty }) {
  const t = toneOf(TONE[difficulty.toLowerCase()] ?? 'slate')
  return (
    <span className={`inline-block rounded-full border px-3 py-1.5 text-xs font-bold uppercase ${t.soft} ${t.text}`} style={{ borderColor: `color-mix(in srgb, ${t.color} 50%, transparent)` }}>
      {difficulty}
    </span>
  )
}
