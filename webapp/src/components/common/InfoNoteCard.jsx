import { tone as toneOf } from '../../theme/tones'

// Quiet tinted note: an icon beside a short sentence.
export default function InfoNoteCard({ icon: Icon, tone, message }) {
  const t = toneOf(tone)
  return (
    <div className={`flex items-start gap-3 rounded-[18px] p-4 ${t.soft}`}>
      <Icon size={22} className={`shrink-0 ${t.text}`} aria-hidden="true" />
      <p className="text-[13px] leading-normal text-ink">{message}</p>
    </div>
  )
}
