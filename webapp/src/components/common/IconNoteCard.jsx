import { tone as toneOf } from '../../theme/tones'

// Quiet outlined note: an icon in a tinted circle beside a bold line and a
// muted one (e.g. "Your learning journey is safe").
export default function IconNoteCard({ icon: Icon, tone = 'rose', title, message }) {
  const t = toneOf(tone)
  return (
    <div className="flex items-center gap-3.5 rounded-2xl border border-glass-line bg-field px-4 py-3.5">
      <span aria-hidden="true" className={`grid size-11 shrink-0 place-items-center rounded-full ${t.soft} ${t.text}`}>
        <Icon size={22} />
      </span>
      <div className="min-w-0">
        <p className="text-[15px] font-semibold text-ink">{title}</p>
        {message ? <p className="mt-0.5 text-[13px] leading-normal text-muted">{message}</p> : null}
      </div>
    </div>
  )
}
