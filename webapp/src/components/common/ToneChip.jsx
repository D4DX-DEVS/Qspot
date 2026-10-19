import { tone as toneOf } from '../../theme/tones'

// Small rounded status label on the soft tint of an accent tone.
export default function ToneChip({ label, tone }) {
  const t = toneOf(tone)
  return (
    <span className={`inline-block shrink-0 whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-semibold ${t.soft} ${t.text}`}>
      {label}
    </span>
  )
}
