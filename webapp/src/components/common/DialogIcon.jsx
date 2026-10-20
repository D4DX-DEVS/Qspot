import { tone as toneOf } from '../../theme/tones'

// Big round icon at the top of a centred dialog, on a soft tint with a glow
// in the same tone; it pops in just after the dialog.
export default function DialogIcon({ icon: Icon, tone = 'rose' }) {
  const t = toneOf(tone)
  return (
    <span
      className={`qs-icon-pop grid size-[72px] place-items-center rounded-full ${t.soft} ${t.text}`}
      style={{ boxShadow: `0 0 30px color-mix(in srgb, ${t.color} 30%, transparent)` }}
    >
      <Icon size={34} aria-hidden="true" />
    </span>
  )
}
