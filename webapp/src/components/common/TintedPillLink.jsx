import { ArrowRight } from 'lucide-react'
import { tone as toneOf } from '../../theme/tones'

// Small soft pill with a label and an arrow, e.g. "Send Now ->". Without
// [onClick] it is decoration inside a card that handles the tap.
export default function TintedPillLink({ label, tone, onClick, disabled = false }) {
  const t = toneOf(tone)
  const body = (
    <>
      <span className="truncate">{label}</span>
      <ArrowRight size={16} aria-hidden="true" className="shrink-0" />
    </>
  )
  const classes = `inline-flex max-w-full items-center gap-1.5 rounded-full px-3.5 py-2 text-[12.5px] font-semibold ${t.soft} ${t.text}`
  if (!onClick) return <span className={classes}>{body}</span>
  return (
    <button type="button" onClick={onClick} disabled={disabled} className={`qs-press [--qs-press:0.94] disabled:opacity-60 ${classes}`}>
      {body}
    </button>
  )
}
